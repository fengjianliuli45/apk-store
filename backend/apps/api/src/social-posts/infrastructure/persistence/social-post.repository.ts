import { NullableType } from '../../../utils/types/nullable.type';
import { CursorPage } from '../../../common/pagination/cursor';
import { SocialPost } from '../../domain/social-post';

export abstract class SocialPostRepository {
  abstract create(
    data: Omit<
      SocialPost,
      'id' | 'createdAt' | 'deletedAt' | 'likeCount' | 'commentCount'
    >,
  ): Promise<SocialPost>;

  abstract findById(id: string): Promise<NullableType<SocialPost>>;

  abstract softDelete(id: string): Promise<void>;

  abstract bumpCounters(
    id: string,
    delta: { like?: number; comment?: number },
  ): Promise<void>;

  abstract listByAuthor(
    authorId: number,
    limit: number,
    cursor?: string | null,
  ): Promise<CursorPage<SocialPost>>;

  /** 关注流：作者 ∈ authorIds、未删、作者不在 excludeAuthorIds。 */
  abstract feed(
    authorIds: number[],
    excludeAuthorIds: number[],
    limit: number,
    cursor?: string | null,
  ): Promise<CursorPage<SocialPost>>;
}
