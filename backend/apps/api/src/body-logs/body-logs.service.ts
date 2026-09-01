import { Injectable, NotFoundException } from '@nestjs/common';
import { BodyLogRepository } from './infrastructure/persistence/body-log.repository';
import { BodyLog } from './domain/body-log';
import { CursorPage } from '../common/pagination/cursor';
import { SyncEmitterService } from '../sync-events/sync-emitter.service';
import { UpsertBodyLogDto, ListBodyLogsQueryDto } from './dto/body-log.dto';

export type WriteContext = {
  clientEventId?: string | null;
  occurredAt?: Date;
};

@Injectable()
export class BodyLogsService {
  constructor(
    private readonly repo: BodyLogRepository,
    private readonly sync: SyncEmitterService,
  ) {}

  async upsert(
    userId: number,
    dto: UpsertBodyLogDto,
    ctx?: WriteContext,
  ): Promise<BodyLog> {
    const log = await this.repo.upsert({
      userId,
      measuredOn: dto.measuredOn,
      weightKg: dto.weightKg ?? null,
      bodyFatPct: dto.bodyFatPct ?? null,
      waistCm: dto.waistCm ?? null,
      armCm: dto.armCm ?? null,
      thighCm: dto.thighCm ?? null,
      note: dto.note ?? null,
    });
    await this.sync.emit({
      userId,
      entityType: 'body_log',
      entityId: log.id,
      op: 'update',
      payload: log as unknown as Record<string, unknown>,
      clientEventId: ctx?.clientEventId ?? null,
      occurredAt: ctx?.occurredAt,
    });
    return log;
  }

  list(
    userId: number,
    query: ListBodyLogsQueryDto,
  ): Promise<CursorPage<BodyLog>> {
    return this.repo.list(userId, {
      limit: query.limit ?? 60,
      cursor: query.cursor,
      from: query.from,
      to: query.to,
    });
  }

  async remove(userId: number, id: string, ctx?: WriteContext): Promise<void> {
    const log = await this.repo.findById(id);
    if (!log || log.userId !== userId) {
      throw new NotFoundException({ errors: { bodyLog: 'notFound' } });
    }
    await this.repo.remove(id);
    await this.sync.emit({
      userId,
      entityType: 'body_log',
      entityId: id,
      op: 'delete',
      payload: { id },
      clientEventId: ctx?.clientEventId ?? null,
      occurredAt: ctx?.occurredAt,
    });
  }
}
