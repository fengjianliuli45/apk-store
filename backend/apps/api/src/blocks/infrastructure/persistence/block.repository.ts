export abstract class BlockRepository {
  abstract add(blockerId: number, blockedId: number): Promise<boolean>;
  abstract remove(blockerId: number, blockedId: number): Promise<boolean>;
  abstract exists(blockerId: number, blockedId: number): Promise<boolean>;

  /** 我屏蔽的人 + 屏蔽我的人（关注流双向排除）。 */
  abstract relatedUserIds(userId: number): Promise<number[]>;
}
