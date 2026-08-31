import { PostComment } from '../../../../domain/post-comment';
import { PostCommentEntity } from '../entities/post-comment.entity';

export class PostCommentMapper {
  static toDomain(raw: PostCommentEntity): PostComment {
    const d = new PostComment();
    d.id = raw.id;
    d.postId = raw.postId;
    d.authorId = raw.authorId;
    d.body = raw.body;
    d.moderationStatus = raw.moderationStatus;
    d.createdAt = raw.createdAt;
    d.deletedAt = raw.deletedAt;
    return d;
  }

  static toPersistence(d: PostComment): PostCommentEntity {
    const e = new PostCommentEntity();
    if (d.id) {
      e.id = d.id;
    }
    e.postId = d.postId;
    e.authorId = d.authorId;
    e.body = d.body;
    e.moderationStatus = d.moderationStatus;
    e.createdAt = d.createdAt;
    e.deletedAt = d.deletedAt ?? null;
    return e;
  }
}
