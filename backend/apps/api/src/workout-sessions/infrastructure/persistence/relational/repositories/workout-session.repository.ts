import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { WorkoutSessionEntity } from '../entities/workout-session.entity';
import { NullableType } from '../../../../../utils/types/nullable.type';
import { DeepPartial } from '../../../../../utils/types/deep-partial.type';
import {
  CursorPage,
  decodeCursor,
  toCursorPage,
} from '../../../../../common/pagination/cursor';
import { WorkoutSession } from '../../../../domain/workout-session';
import { WorkoutSessionRepository } from '../../workout-session.repository';
import { WorkoutSessionMapper } from '../mappers/workout-session.mapper';

@Injectable()
export class WorkoutSessionRelationalRepository implements WorkoutSessionRepository {
  constructor(
    @InjectRepository(WorkoutSessionEntity)
    private readonly repo: Repository<WorkoutSessionEntity>,
  ) {}

  async create(
    data: Omit<WorkoutSession, 'id' | 'createdAt' | 'updatedAt'>,
  ): Promise<WorkoutSession> {
    const entity = this.repo.create(
      WorkoutSessionMapper.toPersistence(data as WorkoutSession),
    );
    const saved = await this.repo.save(entity);
    return WorkoutSessionMapper.toDomain(saved);
  }

  async findById(id: string): Promise<NullableType<WorkoutSession>> {
    const entity = await this.repo.findOne({ where: { id } });
    return entity ? WorkoutSessionMapper.toDomain(entity) : null;
  }

  async listByUser(
    userId: number,
    limit: number,
    cursor?: string | null,
    filters?: {
      from?: string;
      to?: string;
      status?: string;
      planVersionId?: string;
    },
  ): Promise<CursorPage<WorkoutSession>> {
    const qb = this.repo
      .createQueryBuilder('s')
      .where('s.userId = :userId', { userId })
      .orderBy('s.createdAt', 'DESC')
      .addOrderBy('s.id', 'DESC')
      .take(limit + 1);

    if (filters?.from) {
      qb.andWhere('s.scheduledDate >= :from', { from: filters.from });
    }
    if (filters?.to) {
      qb.andWhere('s.scheduledDate <= :to', { to: filters.to });
    }
    if (filters?.status) {
      qb.andWhere('s.status = :status', { status: filters.status });
    }
    if (filters?.planVersionId) {
      qb.andWhere('s.planVersionId = :pv', { pv: filters.planVersionId });
    }

    const decoded = decodeCursor(cursor);
    if (decoded) {
      qb.andWhere('(s.createdAt, s.id) < (:t, :i)', {
        t: decoded.t,
        i: decoded.i,
      });
    }

    const rows = await qb.getMany();
    return toCursorPage(
      rows.map((r) => WorkoutSessionMapper.toDomain(r)),
      limit,
      (r) => ({ createdAt: r.createdAt, id: r.id }),
    );
  }

  async update(
    id: string,
    payload: DeepPartial<WorkoutSession>,
  ): Promise<WorkoutSession | null> {
    const entity = await this.repo.findOne({ where: { id } });
    if (!entity) {
      return null;
    }
    const updated = await this.repo.save(
      this.repo.create(
        WorkoutSessionMapper.toPersistence({
          ...WorkoutSessionMapper.toDomain(entity),
          ...payload,
        } as WorkoutSession),
      ),
    );
    return WorkoutSessionMapper.toDomain(updated);
  }
}
