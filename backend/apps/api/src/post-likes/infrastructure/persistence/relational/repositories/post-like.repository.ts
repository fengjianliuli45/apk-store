import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { PostLikeEntity } from '../entities/post-like.entity';
import { PostLikeRepository } from '../../post-like.repository';
import { newId } from '../../../../../common/id/uuid';

@Injectable()
export class PostLikeRelationalRepository implements PostLikeRepository {
  constructor(
    @InjectRepository(PostLikeEntity)
    private readonly repo: Repository<PostLikeEntity>,
  ) {}

  async add(postId: string, userId: number): Promise<boolean> {
    const res = await this.repo
      .createQueryBuilder()
      .insert()
      .values({ id: newId(), postId, userId })
      .orIgnore()
      .returning('id')
      .execute();
    return Array.isArray(res.raw) && res.raw.length > 0;
  }

  async remove(postId: string, userId: number): Promise<boolean> {
    const res = await this.repo.delete({ postId, userId });
    return (res.affected ?? 0) > 0;
  }

  async likedPostIds(userId: number, postIds: string[]): Promise<string[]> {
    if (postIds.length === 0) {
      return [];
    }
    const rows = await this.repo.find({
      where: { userId, postId: In(postIds) },
      select: { postId: true },
    });
    return rows.map((r) => r.postId);
  }
}
