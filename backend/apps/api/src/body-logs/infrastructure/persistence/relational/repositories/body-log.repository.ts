import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { BodyLogEntity } from '../entities/body-log.entity';
import { NullableType } from '../../../../../utils/types/nullable.type';
import {
  CursorPage,
  decodeCursor,
  toCursorPage,
} from '../../../../../common/pagination/cursor';
import { BodyLog } from '../../../../domain/body-log';
import { BodyLogRepository } from '../../body-log.repository';
import { BodyLogMapper } from '../mappers/body-log.mapper';

@Injectable()
export class BodyLogRelationalRepository implements BodyLogRepository {
  constructor(
    @InjectRepository(BodyLogEntity)
    private readonly repo: Repository<BodyLogEntity>,
  ) {}

  async upsert(
    data: Omit<BodyLog, 'id' | 'createdAt' | 'updatedAt'>,
  ): Promise<BodyLog> {
    const existing = await this.repo.findOne({
      where: { userId: data.userId, measuredOn: data.measuredOn },
    });
    const entity = existing
      ? this.repo.merge(existing, {
          weightKg: data.weightKg ?? null,
          bodyFatPct: data.bodyFatPct ?? null,
          waistCm: data.waistCm ?? null,
          armCm: data.armCm ?? null,
          thighCm: data.thighCm ?? null,
          note: data.note ?? null,
        })
      : this.repo.create({
          userId: data.userId,
          measuredOn: data.measuredOn,
          weightKg: data.weightKg ?? null,
          bodyFatPct: data.bodyFatPct ?? null,
          waistCm: data.waistCm ?? null,
          armCm: data.armCm ?? null,
          thighCm: data.thighCm ?? null,
          note: data.note ?? null,
        });
    const saved = await this.repo.save(entity);
    return BodyLogMapper.toDomain(saved);
  }

  async findById(id: string): Promise<NullableType<BodyLog>> {
    const entity = await this.repo.findOne({ where: { id } });
    return entity ? BodyLogMapper.toDomain(entity) : null;
  }

  async remove(id: string): Promise<void> {
    await this.repo.delete({ id });
  }

  async list(
    userId: number,
    opts: { limit: number; cursor?: string | null; from?: string; to?: string },
  ): Promise<CursorPage<BodyLog>> {
    const qb = this.repo
      .createQueryBuilder('b')
      .where('b.userId = :userId', { userId })
      .orderBy('b.measuredOn', 'DESC')
      .addOrderBy('b.id', 'DESC')
      .take(opts.limit + 1);

    if (opts.from) {
      qb.andWhere('b.measuredOn >= :from', { from: opts.from });
    }
    if (opts.to) {
      qb.andWhere('b.measuredOn <= :to', { to: opts.to });
    }

    const decoded = decodeCursor(opts.cursor);
    if (decoded) {
      qb.andWhere('(b.measuredOn, b.id) < (:t, :i)', {
        t: decoded.t,
        i: decoded.i,
      });
    }

    const rows = await qb.getMany();
    return toCursorPage(
      rows.map((r) => BodyLogMapper.toDomain(r)),
      opts.limit,
      (r) => ({ createdAt: r.measuredOn, id: r.id }),
    );
  }
}
