export abstract class PostLikeRepository {
  /** 幂等：已点过返回 false。 */
  abstract add(postId: string, userId: number): Promise<boolean>;

  /** 幂等：本来没点返回 false。 */
  abstract remove(postId: string, userId: number): Promise<boolean>;

  /** postIds 里当前用户点过赞的子集。 */
  abstract likedPostIds(userId: number, postIds: string[]): Promise<string[]>;
}
