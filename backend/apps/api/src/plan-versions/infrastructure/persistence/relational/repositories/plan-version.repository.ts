import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { PlanVersionEntity } from '../entities/plan-version.entity';
import { NullableType } from '../../../../../utils/types/nullable.type';
import {
  CursorPage,
  decodeCursor,
  toCursorPage,
} from '../../../../../common/pagination/cursor';
import { PlanVersion } from '../../../../domain/plan-version';
import { PlanVersionRepository } from '../../plan-version.repository';
import { PlanVersionMapper } from '../mappers/plan-version.mapper';

@Injectable()
export class PlanVersionRelationalRepository implements PlanVersionRepository {
  constructor(
    @InjectRepository(PlanVersionEntity)
    private readonly repo: Repository<PlanVersionEntity>,
  ) {}

  async create(
    data: Omit<PlanVersion, 'id' | 'createdAt'>,
  ): Promise<PlanVersion> {
    const entity = this.repo.create(
      PlanVersionMapper.toPersistence(data as PlanVersion),
    );
    const saved = await this.repo.save(entity);
    return PlanVersionMapper.toDomain(saved);
  }

  async findById(id: string): Promise<NullableType<PlanVersion>> {
    const entity = await this.repo.findOne({ where: { id } });
    return entity ? PlanVersionMapper.toDomain(entity) : null;
  }

  async listByPlan(
    planId: string,
    limit: number,
    cursor?: string | null,
  ): Promise<CursorPage<PlanVersion>> {
    const qb = this.repo
      .createQueryBuilder('v')
      .where('v.planId = :planId', { planId })
      .orderBy('v.createdAt', 'DESC')
      .addOrderBy('v.id', 'DESC')
      .take(limit + 1);

    const decoded = decodeCursor(cursor);
    if (decoded) {
      qb.andWhere('(v.createdAt, v.id) < (:t, :i)', {
        t: decoded.t,
        i: decoded.i,
      });
    }

    const rows = await qb.getMany();
    return toCursorPage(
      rows.map((r) => PlanVersionMapper.toDomain(r)),
      limit,
      (r) => ({ createdAt: r.createdAt, id: r.id }),
    );
  }
}
