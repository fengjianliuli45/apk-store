import { PostVisibility, SocialPost } from '../../../../domain/social-post';
import { SocialPostEntity } from '../entities/social-post.entity';

export class SocialPostMapper {
  static toDomain(raw: SocialPostEntity): SocialPost {
    const d = new SocialPost();
    d.id = raw.id;
    d.authorId = raw.authorId;
    d.kind = raw.kind;
    d.body = raw.body;
    d.mediaIds = raw.mediaIds ?? [];
    d.refType = raw.refType;
    d.refId = raw.refId;
    d.visibility = raw.visibility as PostVisibility;
    d.likeCount = raw.likeCount;
    d.commentCount = raw.commentCount;
    d.moderationStatus = raw.moderationStatus;
    d.createdAt = raw.createdAt;
    d.deletedAt = raw.deletedAt;
    return d;
  }

  static toPersistence(d: SocialPost): SocialPostEntity {
    const e = new SocialPostEntity();
    if (d.id) {
      e.id = d.id;
    }
    e.authorId = d.authorId;
    e.kind = d.kind;
    e.body = d.body;
    e.mediaIds = d.mediaIds ?? [];
    e.refType = d.refType ?? null;
    e.refId = d.refId ?? null;
    e.visibility = d.visibility;
    e.likeCount = d.likeCount;
    e.commentCount = d.commentCount;
    e.moderationStatus = d.moderationStatus;
    e.createdAt = d.createdAt;
    e.deletedAt = d.deletedAt ?? null;
    return e;
  }
}
