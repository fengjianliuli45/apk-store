import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { FollowEntity } from '../entities/follow.entity';
import { FollowRepository } from '../../follow.repository';
import { FollowMapper } from '../mappers/follow.mapper';
import {
  CursorPage,
  decodeCursor,
  toCursorPage,
} from '../../../../../common/pagination/cursor';
import { Follow } from '../../../../domain/follow';
import { newId } from '../../../../../common/id/uuid';

@Injectable()
export class FollowRelationalRepository implements FollowRepository {
  constructor(
    @InjectRepository(FollowEntity)
    private readonly repo: Repository<FollowEntity>,
  ) {}

  async add(followerId: number, followeeId: number): Promise<boolean> {
    const res = await this.repo
      .createQueryBuilder()
      .insert()
      .values({ id: newId(), followerId, followeeId })
      .orIgnore()
      .returning('id')
      .execute();
    return Array.isArray(res.raw) && res.raw.length > 0;
  }

  async remove(followerId: number, followeeId: number): Promise<boolean> {
    const res = await this.repo.delete({ followerId, followeeId });
    return (res.affected ?? 0) > 0;
  }

  async exists(followerId: number, followeeId: number): Promise<boolean> {
    return (await this.repo.countBy({ followerId, followeeId })) > 0;
  }

  async followeeIds(followerId: number): Promise<number[]> {
    const rows = await this.repo.find({
      where: { followerId },
      select: { followeeId: true },
    });
    return rows.map((r) => r.followeeId);
  }

  countFollowers(userId: number): Promise<number> {
    return this.repo.countBy({ followeeId: userId });
  }

  countFollowing(userId: number): Promise<number> {
    return this.repo.countBy({ followerId: userId });
  }

  listFollowers(
    userId: number,
    limit: number,
    cursor?: string | null,
  ): Promise<CursorPage<Follow>> {
    return this.page(
      this.repo
        .createQueryBuilder('f')
        .where('f.followeeId = :userId', { userId }),
      limit,
      cursor,
    );
  }

  listFollowing(
    userId: number,
    limit: number,
    cursor?: string | null,
  ): Promise<CursorPage<Follow>> {
    return this.page(
      this.repo
        .createQueryBuilder('f')
        .where('f.followerId = :userId', { userId }),
      limit,
      cursor,
    );
  }

  private async page(
    qb: ReturnType<Repository<FollowEntity>['createQueryBuilder']>,
    limit: number,
    cursor?: string | null,
  ): Promise<CursorPage<Follow>> {
    qb.orderBy('f.createdAt', 'DESC')
      .addOrderBy('f.id', 'DESC')
      .take(limit + 1);
    const decoded = decodeCursor(cursor);
    if (decoded) {
      qb.andWhere('(f.createdAt, f.id) < (:t, :i)', {
        t: decoded.t,
        i: decoded.i,
      });
    }
    const rows = await qb.getMany();
    return toCursorPage(
      rows.map((r) => FollowMapper.toDomain(r)),
      limit,
      (r) => ({ createdAt: r.createdAt, id: r.id }),
    );
  }
}
