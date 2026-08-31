import {
  ForbiddenException,
  Injectable,
  NotFoundException,
  UnprocessableEntityException,
} from '@nestjs/common';
import { SocialPostRepository } from '../social-posts/infrastructure/persistence/social-post.repository';
import { PostCommentRepository } from '../post-comments/infrastructure/persistence/post-comment.repository';
import { PostLikeRepository } from '../post-likes/infrastructure/persistence/post-like.repository';
import { FollowRepository } from '../follows/infrastructure/persistence/follow.repository';
import { BlockRepository } from '../blocks/infrastructure/persistence/block.repository';
import { ReportRepository } from '../reports/infrastructure/persistence/report.repository';
import { MediaObjectsService } from '../media-objects/media-objects.service';
import { NotificationsService } from '../notifications/notifications.service';
import { SocialPost, PostVisibility } from '../social-posts/domain/social-post';
import { PostComment } from '../post-comments/domain/post-comment';
import { Follow } from '../follows/domain/follow';
import { CursorPage } from '../common/pagination/cursor';
import { CreatePostDto } from './dto/create-post.dto';
import { AddCommentDto, CreateReportDto } from './dto/social-misc.dto';

export type PostView = SocialPost & { liked: boolean };

const MAX_REPORTS_PER_DAY = 20;

@Injectable()
export class SocialService {
  constructor(
    private readonly posts: SocialPostRepository,
    private readonly comments: PostCommentRepository,
    private readonly likes: PostLikeRepository,
    private readonly follows: FollowRepository,
    private readonly blocks: BlockRepository,
    private readonly reports: ReportRepository,
    private readonly media: MediaObjectsService,
    private readonly notifications: NotificationsService,
  ) {}

  // ── posts ──────────────────────────────────────────────

  async createPost(userId: number, dto: CreatePostDto): Promise<PostView> {
    const mediaIds = dto.mediaIds ?? [];
    for (const id of mediaIds) {
      await this.media.assertUsable(userId, id);
    }
    // TODO(§9.5): 发帖过内容安全 API（图文 + refId 归属校验），结果回写 moderationStatus。
    const post = await this.posts.create({
      authorId: userId,
      kind: dto.kind ?? 'text',
      body: dto.body,
      mediaIds,
      refType: dto.refType ?? null,
      refId: dto.refType ? (dto.refId ?? null) : null,
      visibility: (dto.visibility ?? 'public') as PostVisibility,
      moderationStatus: 'pending',
    });
    return { ...post, liked: false };
  }

  async getPost(viewerId: number, postId: string): Promise<PostView> {
    const post = await this.posts.findById(postId);
    if (!post) {
      throw new NotFoundException({ errors: { post: 'notFound' } });
    }
    if (post.authorId !== viewerId) {
      await this.assertNotBlocked(viewerId, post.authorId);
      if (
        post.visibility === 'followers' &&
        !(await this.follows.exists(viewerId, post.authorId))
      ) {
        throw new NotFoundException({ errors: { post: 'notFound' } });
      }
    }
    const [liked] = await this.likes.likedPostIds(viewerId, [postId]);
    return { ...post, liked: !!liked };
  }

  async deletePost(userId: number, postId: string): Promise<void> {
    const post = await this.posts.findById(postId);
    if (!post) {
      throw new NotFoundException({ errors: { post: 'notFound' } });
    }
    if (post.authorId !== userId) {
      throw new ForbiddenException({ errors: { post: 'notOwner' } });
    }
    await this.posts.softDelete(postId);
  }

  async getFeed(
    viewerId: number,
    limit: number,
    cursor?: string | null,
  ): Promise<CursorPage<PostView>> {
    const followeeIds = await this.follows.followeeIds(viewerId);
    const authorIds = [...new Set([...followeeIds, viewerId])];
    const excluded = await this.blocks.relatedUserIds(viewerId);
    const page = await this.posts.feed(authorIds, excluded, limit, cursor);
    return this.withLiked(viewerId, page);
  }

  async getUserPosts(
    viewerId: number,
    targetUserId: number,
    limit: number,
    cursor?: string | null,
  ): Promise<CursorPage<PostView>> {
    if (viewerId !== targetUserId) {
      await this.assertNotBlocked(viewerId, targetUserId);
    }
    const page = await this.posts.listByAuthor(targetUserId, limit, cursor);
    const following =
      viewerId === targetUserId ||
      (await this.follows.exists(viewerId, targetUserId));
    page.data = page.data.filter((p) => p.visibility === 'public' || following);
    return this.withLiked(viewerId, page);
  }

  // ── likes ──────────────────────────────────────────────

  async like(userId: number, postId: string): Promise<void> {
    const post = await this.requireVisiblePost(userId, postId);
    const created = await this.likes.add(postId, userId);
    if (created) {
      await this.posts.bumpCounters(postId, { like: 1 });
      if (post.authorId !== userId) {
        await this.notifications.notify(post.authorId, {
          type: 'social_like',
          category: 'social',
          title: '有人赞了你的动态',
          body: '',
          data: { postId },
        });
      }
    }
  }

  async unlike(userId: number, postId: string): Promise<void> {
    const removed = await this.likes.remove(postId, userId);
    if (removed) {
      await this.posts.bumpCounters(postId, { like: -1 });
    }
  }

  // ── comments ───────────────────────────────────────────

  listComments(
    viewerId: number,
    postId: string,
    limit: number,
    cursor?: string | null,
  ): Promise<CursorPage<PostComment>> {
    return this.requireVisiblePost(viewerId, postId).then(() =>
      this.comments.listByPost(postId, limit, cursor),
    );
  }

  async addComment(
    userId: number,
    postId: string,
    dto: AddCommentDto,
  ): Promise<PostComment> {
    const post = await this.requireVisiblePost(userId, postId);
    // TODO(§9.5): 评论过内容安全。
    const comment = await this.comments.create({
      postId,
      authorId: userId,
      body: dto.body,
      moderationStatus: 'pending',
    });
    await this.posts.bumpCounters(postId, { comment: 1 });
    if (post.authorId !== userId) {
      await this.notifications.notify(post.authorId, {
        type: 'social_comment',
        category: 'social',
        title: '有人评论了你的动态',
        body: dto.body.slice(0, 80),
        data: { postId, commentId: comment.id },
      });
    }
    return comment;
  }

  async deleteComment(userId: number, commentId: string): Promise<void> {
    const comment = await this.comments.findById(commentId);
    if (!comment) {
      throw new NotFoundException({ errors: { comment: 'notFound' } });
    }
    const post = await this.posts.findById(comment.postId);
    const canDelete = comment.authorId === userId || post?.authorId === userId;
    if (!canDelete) {
      throw new ForbiddenException({ errors: { comment: 'notOwner' } });
    }
    await this.comments.softDelete(commentId);
    await this.posts.bumpCounters(comment.postId, { comment: -1 });
  }

  // ── follow ─────────────────────────────────────────────

  async follow(userId: number, targetId: number): Promise<void> {
    if (userId === targetId) {
      throw new UnprocessableEntityException({
        errors: { follow: 'self' },
      });
    }
    if (await this.blocks.exists(targetId, userId)) {
      throw new ForbiddenException({ errors: { follow: 'blocked' } });
    }
    const created = await this.follows.add(userId, targetId);
    if (created) {
      await this.notifications.notify(targetId, {
        type: 'social_follow',
        category: 'social',
        title: '有新粉丝关注了你',
        body: '',
        data: { followerId: userId },
      });
    }
  }

  unfollow(userId: number, targetId: number): Promise<boolean> {
    return this.follows.remove(userId, targetId);
  }

  listFollowers(
    userId: number,
    limit: number,
    cursor?: string | null,
  ): Promise<CursorPage<Follow>> {
    return this.follows.listFollowers(userId, limit, cursor);
  }

  listFollowing(
    userId: number,
    limit: number,
    cursor?: string | null,
  ): Promise<CursorPage<Follow>> {
    return this.follows.listFollowing(userId, limit, cursor);
  }

  async followStats(
    viewerId: number,
    targetId: number,
  ): Promise<{
    followers: number;
    following: number;
    isFollowing: boolean;
  }> {
    const [followers, following, isFollowing] = await Promise.all([
      this.follows.countFollowers(targetId),
      this.follows.countFollowing(targetId),
      viewerId === targetId
        ? Promise.resolve(false)
        : this.follows.exists(viewerId, targetId),
    ]);
    return { followers, following, isFollowing };
  }

  // ── block ──────────────────────────────────────────────

  async block(userId: number, targetId: number): Promise<void> {
    if (userId === targetId) {
      throw new UnprocessableEntityException({ errors: { block: 'self' } });
    }
    await this.blocks.add(userId, targetId);
    // 互相取关
    await this.follows.remove(userId, targetId);
    await this.follows.remove(targetId, userId);
  }

  unblock(userId: number, targetId: number): Promise<boolean> {
    return this.blocks.remove(userId, targetId);
  }

  // ── report ─────────────────────────────────────────────

  async report(userId: number, dto: CreateReportDto): Promise<void> {
    const since = new Date(Date.now() - 24 * 60 * 60 * 1000);
    const count = await this.reports.countOpenByReporterSince(userId, since);
    if (count >= MAX_REPORTS_PER_DAY) {
      throw new UnprocessableEntityException({
        errors: { report: 'dailyLimit' },
      });
    }
    await this.reports.create({
      reporterId: userId,
      targetType: dto.targetType as never,
      targetId: dto.targetId,
      reason: dto.reason,
      detail: dto.detail ?? null,
    });
  }

  // ── helpers ────────────────────────────────────────────

  private async assertNotBlocked(a: number, b: number): Promise<void> {
    if ((await this.blocks.exists(a, b)) || (await this.blocks.exists(b, a))) {
      throw new NotFoundException({ errors: { user: 'notFound' } });
    }
  }

  private async requireVisiblePost(
    viewerId: number,
    postId: string,
  ): Promise<SocialPost> {
    const view = await this.getPost(viewerId, postId);
    return view;
  }

  private async withLiked(
    viewerId: number,
    page: CursorPage<SocialPost>,
  ): Promise<CursorPage<PostView>> {
    const likedIds = new Set(
      await this.likes.likedPostIds(
        viewerId,
        page.data.map((p) => p.id),
      ),
    );
    return {
      data: page.data.map((p) => ({ ...p, liked: likedIds.has(p.id) })),
      nextCursor: page.nextCursor,
    };
  }
}
