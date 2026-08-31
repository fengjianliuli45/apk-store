import { PostLike } from '../../../../domain/post-like';
import { PostLikeEntity } from '../entities/post-like.entity';

export class PostLikeMapper {
  static toDomain(raw: PostLikeEntity): PostLike {
    const d = new PostLike();
    d.id = raw.id;
    d.postId = raw.postId;
    d.userId = raw.userId;
    d.createdAt = raw.createdAt;
    return d;
  }

  static toPersistence(d: PostLike): PostLikeEntity {
    const e = new PostLikeEntity();
    if (d.id) {
      e.id = d.id;
    }
    e.postId = d.postId;
    e.userId = d.userId;
    e.createdAt = d.createdAt;
    return e;
  }
}
