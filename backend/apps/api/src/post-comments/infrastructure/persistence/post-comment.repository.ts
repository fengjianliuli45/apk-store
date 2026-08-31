import { NullableType } from '../../../utils/types/nullable.type';
import { CursorPage } from '../../../common/pagination/cursor';
import { PostComment } from '../../domain/post-comment';

export abstract class PostCommentRepository {
  abstract create(
    data: Omit<PostComment, 'id' | 'createdAt' | 'deletedAt'>,
  ): Promise<PostComment>;

  abstract findById(id: string): Promise<NullableType<PostComment>>;

  abstract softDelete(id: string): Promise<void>;

  abstract listByPost(
    postId: string,
    limit: number,
    cursor?: string | null,
  ): Promise<CursorPage<PostComment>>;
}
