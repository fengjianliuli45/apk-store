import { CursorPage } from '../../../common/pagination/cursor';
import { Follow } from '../../domain/follow';

export abstract class FollowRepository {
  abstract add(followerId: number, followeeId: number): Promise<boolean>;
  abstract remove(followerId: number, followeeId: number): Promise<boolean>;
  abstract exists(followerId: number, followeeId: number): Promise<boolean>;

  abstract followeeIds(followerId: number): Promise<number[]>;
  abstract countFollowers(userId: number): Promise<number>;
  abstract countFollowing(userId: number): Promise<number>;

  abstract listFollowers(
    userId: number,
    limit: number,
    cursor?: string | null,
  ): Promise<CursorPage<Follow>>;
  abstract listFollowing(
    userId: number,
    limit: number,
    cursor?: string | null,
  ): Promise<CursorPage<Follow>>;
}
