import {
  ForbiddenException,
  NotFoundException,
  UnprocessableEntityException,
} from '@nestjs/common';
import { SocialService } from './social.service';
import { SocialPost } from '../social-posts/domain/social-post';
import { SocialPostRepository } from '../social-posts/infrastructure/persistence/social-post.repository';
import { PostComment } from '../post-comments/domain/post-comment';
import { PostCommentRepository } from '../post-comments/infrastructure/persistence/post-comment.repository';
import { PostLikeRepository } from '../post-likes/infrastructure/persistence/post-like.repository';
import { Follow } from '../follows/domain/follow';
import { FollowRepository } from '../follows/infrastructure/persistence/follow.repository';
import { BlockRepository } from '../blocks/infrastructure/persistence/block.repository';
import { Report } from '../reports/domain/report';
import { ReportRepository } from '../reports/infrastructure/persistence/report.repository';
import { CursorPage } from '../common/pagination/cursor';
import { MediaObjectsService } from '../media-objects/media-objects.service';
import { NotificationsService } from '../notifications/notifications.service';

const page = <T>(data: T[]): CursorPage<T> => ({ data, nextCursor: null });

class PostRepo implements SocialPostRepository {
  rows: SocialPost[] = [];
  seq = 0;
  create(
    d: Omit<
      SocialPost,
      'id' | 'createdAt' | 'deletedAt' | 'likeCount' | 'commentCount'
    >,
  ) {
    const row: SocialPost = {
      ...(d as SocialPost),
      id: `post-${++this.seq}`,
      likeCount: 0,
      commentCount: 0,
      createdAt: new Date(Date.now() + this.seq),
      deletedAt: null,
    };
    this.rows.push(row);
    return Promise.resolve(row);
  }
  findById(id: string) {
    return Promise.resolve(
      this.rows.find((r) => r.id === id && !r.deletedAt) ?? null,
    );
  }
  softDelete(id: string) {
    const r = this.rows.find((x) => x.id === id);
    if (r) r.deletedAt = new Date();
    return Promise.resolve();
  }
  bumpCounters(id: string, delta: { like?: number; comment?: number }) {
    const r = this.rows.find((x) => x.id === id);
    if (r) {
      r.likeCount += delta.like ?? 0;
      r.commentCount += delta.comment ?? 0;
    }
    return Promise.resolve();
  }
  listByAuthor(authorId: number) {
    return Promise.resolve(
      page(this.rows.filter((r) => r.authorId === authorId && !r.deletedAt)),
    );
  }
  feed(authorIds: number[], excludeAuthorIds: number[]) {
    return Promise.resolve(
      page(
        this.rows.filter(
          (r) =>
            !r.deletedAt &&
            authorIds.includes(r.authorId) &&
            !excludeAuthorIds.includes(r.authorId),
        ),
      ),
    );
  }
}

class CommentRepo implements PostCommentRepository {
  rows: PostComment[] = [];
  seq = 0;
  create(d: Omit<PostComment, 'id' | 'createdAt' | 'deletedAt'>) {
    const row: PostComment = {
      ...(d as PostComment),
      id: `c-${++this.seq}`,
      createdAt: new Date(),
      deletedAt: null,
    };
    this.rows.push(row);
    return Promise.resolve(row);
  }
  findById(id: string) {
    return Promise.resolve(
      this.rows.find((r) => r.id === id && !r.deletedAt) ?? null,
    );
  }
  softDelete(id: string) {
    const r = this.rows.find((x) => x.id === id);
    if (r) r.deletedAt = new Date();
    return Promise.resolve();
  }
  listByPost(postId: string) {
    return Promise.resolve(
      page(this.rows.filter((r) => r.postId === postId && !r.deletedAt)),
    );
  }
}

class LikeRepo implements PostLikeRepository {
  rows: { postId: string; userId: number }[] = [];
  add(postId: string, userId: number) {
    if (this.rows.some((r) => r.postId === postId && r.userId === userId)) {
      return Promise.resolve(false);
    }
    this.rows.push({ postId, userId });
    return Promise.resolve(true);
  }
  remove(postId: string, userId: number) {
    const before = this.rows.length;
    this.rows = this.rows.filter(
      (r) => !(r.postId === postId && r.userId === userId),
    );
    return Promise.resolve(this.rows.length < before);
  }
  likedPostIds(userId: number, postIds: string[]) {
    return Promise.resolve(
      this.rows
        .filter((r) => r.userId === userId && postIds.includes(r.postId))
        .map((r) => r.postId),
    );
  }
}

class FollowRepo implements FollowRepository {
  rows: { followerId: number; followeeId: number }[] = [];
  add(a: number, b: number) {
    if (this.rows.some((r) => r.followerId === a && r.followeeId === b)) {
      return Promise.resolve(false);
    }
    this.rows.push({ followerId: a, followeeId: b });
    return Promise.resolve(true);
  }
  remove(a: number, b: number) {
    const before = this.rows.length;
    this.rows = this.rows.filter(
      (r) => !(r.followerId === a && r.followeeId === b),
    );
    return Promise.resolve(this.rows.length < before);
  }
  exists(a: number, b: number) {
    return Promise.resolve(
      this.rows.some((r) => r.followerId === a && r.followeeId === b),
    );
  }
  followeeIds(a: number) {
    return Promise.resolve(
      this.rows.filter((r) => r.followerId === a).map((r) => r.followeeId),
    );
  }
  countFollowers(u: number) {
    return Promise.resolve(this.rows.filter((r) => r.followeeId === u).length);
  }
  countFollowing(u: number) {
    return Promise.resolve(this.rows.filter((r) => r.followerId === u).length);
  }
  listFollowers(): Promise<CursorPage<Follow>> {
    return Promise.resolve(page([]));
  }
  listFollowing(): Promise<CursorPage<Follow>> {
    return Promise.resolve(page([]));
  }
}

class BlockRepo implements BlockRepository {
  rows: { blockerId: number; blockedId: number }[] = [];
  add(a: number, b: number) {
    if (this.rows.some((r) => r.blockerId === a && r.blockedId === b)) {
      return Promise.resolve(false);
    }
    this.rows.push({ blockerId: a, blockedId: b });
    return Promise.resolve(true);
  }
  remove(a: number, b: number) {
    const before = this.rows.length;
    this.rows = this.rows.filter(
      (r) => !(r.blockerId === a && r.blockedId === b),
    );
    return Promise.resolve(this.rows.length < before);
  }
  exists(a: number, b: number) {
    return Promise.resolve(
      this.rows.some((r) => r.blockerId === a && r.blockedId === b),
    );
  }
  relatedUserIds(u: number) {
    const ids = new Set<number>();
    for (const r of this.rows) {
      if (r.blockerId === u) ids.add(r.blockedId);
      if (r.blockedId === u) ids.add(r.blockerId);
    }
    return Promise.resolve([...ids]);
  }
}

class ReportRepo implements ReportRepository {
  rows: Report[] = [];
  create(d: Omit<Report, 'id' | 'createdAt' | 'status'>) {
    const row: Report = {
      ...(d as Report),
      id: `r-${this.rows.length + 1}`,
      status: 'open',
      createdAt: new Date(),
    };
    this.rows.push(row);
    return Promise.resolve(row);
  }
  countOpenByReporterSince(reporterId: number) {
    return Promise.resolve(
      this.rows.filter((r) => r.reporterId === reporterId).length,
    );
  }
}

describe('SocialService', () => {
  let postRepo: PostRepo;
  let likeRepo: LikeRepo;
  let followRepo: FollowRepo;
  let blockRepo: BlockRepo;
  let notify: jest.Mock;
  let service: SocialService;

  beforeEach(() => {
    postRepo = new PostRepo();
    likeRepo = new LikeRepo();
    followRepo = new FollowRepo();
    blockRepo = new BlockRepo();
    notify = jest.fn().mockResolvedValue(undefined);
    service = new SocialService(
      postRepo,
      new CommentRepo(),
      likeRepo,
      followRepo,
      blockRepo,
      new ReportRepo(),
      {
        assertUsable: jest.fn().mockResolvedValue({}),
      } as unknown as MediaObjectsService,
      { notify } as unknown as NotificationsService,
    );
  });

  const post = (uid: number, over: Partial<Record<string, unknown>> = {}) =>
    service.createPost(uid, { body: 'hi', ...over });

  it('should show posts from followed users and self in the feed', async () => {
    await post(1); // self
    await post(2); // stranger
    await post(3); // will follow
    await followRepo.add(1, 3);
    const feed = await service.getFeed(1, 20);
    expect(feed.data.map((p) => p.authorId).sort()).toEqual([1, 3]);
  });

  it('should hide blocked users from the feed and drop the follow', async () => {
    await post(3);
    await followRepo.add(1, 3);
    await service.block(1, 3);
    const feed = await service.getFeed(1, 20);
    expect(feed.data).toHaveLength(0);
    expect(await followRepo.exists(1, 3)).toBe(false);
  });

  it('should like idempotently, bump the counter, and notify the author once', async () => {
    const p = await post(2);
    await service.like(1, p.id);
    await service.like(1, p.id);
    expect(postRepo.rows[0].likeCount).toBe(1);
    expect(notify).toHaveBeenCalledTimes(1);
    await service.unlike(1, p.id);
    expect(postRepo.rows[0].likeCount).toBe(0);
  });

  it('should not notify on a self-like', async () => {
    const p = await post(1);
    await service.like(1, p.id);
    expect(notify).not.toHaveBeenCalled();
  });

  it('should bump commentCount and notify on a comment', async () => {
    const p = await post(2);
    await service.addComment(1, p.id, { body: 'nice' });
    expect(postRepo.rows[0].commentCount).toBe(1);
    expect(notify).toHaveBeenCalledWith(
      2,
      expect.objectContaining({ type: 'social_comment' }),
    );
  });

  it('should hide a followers-only post from a non-follower', async () => {
    const p = await post(2, { visibility: 'followers' });
    await expect(service.getPost(1, p.id)).rejects.toBeInstanceOf(
      NotFoundException,
    );
    await followRepo.add(1, 2);
    await expect(service.getPost(1, p.id)).resolves.toMatchObject({ id: p.id });
  });

  it('should reject following yourself', async () => {
    await expect(service.follow(1, 1)).rejects.toBeInstanceOf(
      UnprocessableEntityException,
    );
  });

  it('should only let the author delete their post', async () => {
    const p = await post(2);
    await expect(service.deletePost(1, p.id)).rejects.toBeInstanceOf(
      ForbiddenException,
    );
    await service.deletePost(2, p.id);
    await expect(service.getPost(2, p.id)).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });

  it('should let a post author delete someone elses comment on their post', async () => {
    const p = await post(1);
    const c = await service.addComment(2, p.id, { body: 'x' });
    await expect(service.deleteComment(1, c.id)).resolves.toBeUndefined();
    expect(postRepo.rows[0].commentCount).toBe(0);
  });

  it('should mark liked=true for the viewer in the feed', async () => {
    const p = await post(2);
    await followRepo.add(1, 2);
    await service.like(1, p.id);
    const feed = await service.getFeed(1, 20);
    expect(feed.data[0].liked).toBe(true);
  });
});
