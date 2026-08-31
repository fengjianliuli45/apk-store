import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { BlockEntity } from '../entities/block.entity';
import { BlockRepository } from '../../block.repository';
import { newId } from '../../../../../common/id/uuid';

@Injectable()
export class BlockRelationalRepository implements BlockRepository {
  constructor(
    @InjectRepository(BlockEntity)
    private readonly repo: Repository<BlockEntity>,
  ) {}

  async add(blockerId: number, blockedId: number): Promise<boolean> {
    const res = await this.repo
      .createQueryBuilder()
      .insert()
      .values({ id: newId(), blockerId, blockedId })
      .orIgnore()
      .returning('id')
      .execute();
    return Array.isArray(res.raw) && res.raw.length > 0;
  }

  async remove(blockerId: number, blockedId: number): Promise<boolean> {
    const res = await this.repo.delete({ blockerId, blockedId });
    return (res.affected ?? 0) > 0;
  }

  async exists(blockerId: number, blockedId: number): Promise<boolean> {
    return (await this.repo.countBy({ blockerId, blockedId })) > 0;
  }

  async relatedUserIds(userId: number): Promise<number[]> {
    const rows = await this.repo
      .createQueryBuilder('b')
      .select(['b.blockerId AS "blockerId"', 'b.blockedId AS "blockedId"'])
      .where('b.blockerId = :userId OR b.blockedId = :userId', { userId })
      .getRawMany<{ blockerId: number; blockedId: number }>();
    const ids = new Set<number>();
    for (const r of rows) {
      ids.add(r.blockerId === userId ? r.blockedId : r.blockerId);
    }
    return [...ids];
  }
}
