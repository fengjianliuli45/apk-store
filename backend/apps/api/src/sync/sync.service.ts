import { Injectable, Logger } from '@nestjs/common';
import { SyncEventRepository } from '../sync-events/infrastructure/persistence/sync-event.repository';
import { SyncEvent } from '../sync-events/domain/sync-event';
import {
  WorkoutSessionsService,
  WriteContext,
} from '../workout-sessions/workout-sessions.service';
import { ProfilesService } from '../profiles/profiles.service';
import { BodyLogsService } from '../body-logs/body-logs.service';
import { SyncBatchDto, SyncEventInputDto } from './dto/sync-batch.dto';

export type BatchItemResult = {
  clientEventId: string;
  status: 'applied' | 'duplicate' | 'rejected';
  serverSeq?: number;
  error?: string;
};

export type BatchResult = {
  results: BatchItemResult[];
  syncCursor: number;
};

export type PullResult = {
  events: SyncEvent[];
  nextCursor: number;
  hasMore: boolean;
};

/**
 * 离线增量同步（ADAPTATION_PLAN §9.1，协议见 packages/contracts/sync.md）。
 * push：逐条幂等落库（clientEventId 去重）→ 派发到领域 service。
 * pull：按 serverSeq 拉增量。
 */
@Injectable()
export class SyncService {
  private readonly logger = new Logger('SyncService');

  constructor(
    private readonly repo: SyncEventRepository,
    private readonly workouts: WorkoutSessionsService,
    private readonly profiles: ProfilesService,
    private readonly bodyLogs: BodyLogsService,
  ) {}

  async pushBatch(userId: number, dto: SyncBatchDto): Promise<BatchResult> {
    const results: BatchItemResult[] = [];

    for (const ev of dto.events) {
      const existing = await this.repo.findByUserAndClientEventId(
        userId,
        ev.clientEventId,
      );
      if (existing) {
        results.push({
          clientEventId: ev.clientEventId,
          status: 'duplicate',
          serverSeq: existing.serverSeq,
        });
        continue;
      }

      try {
        await this.dispatch(userId, ev);
        const recorded = await this.repo.findByUserAndClientEventId(
          userId,
          ev.clientEventId,
        );
        results.push({
          clientEventId: ev.clientEventId,
          status: 'applied',
          serverSeq: recorded?.serverSeq,
        });
      } catch (error) {
        this.logger.warn(
          `batch item rejected (${ev.entityType}/${ev.op}): ${
            (error as Error).message
          }`,
        );
        results.push({
          clientEventId: ev.clientEventId,
          status: 'rejected',
          error: (error as Error).message,
        });
      }
    }

    return { results, syncCursor: await this.repo.maxSeq(userId) };
  }

  async pullChanges(
    userId: number,
    cursor: number,
    limit: number,
  ): Promise<PullResult> {
    const rows = await this.repo.listSince(userId, cursor, limit + 1);
    const hasMore = rows.length > limit;
    const events = hasMore ? rows.slice(0, limit) : rows;
    const nextCursor =
      events.length > 0 ? events[events.length - 1].serverSeq : cursor;
    return { events, nextCursor, hasMore };
  }

  private dispatch(userId: number, ev: SyncEventInputDto): Promise<unknown> {
    const ctx: WriteContext = {
      clientEventId: ev.clientEventId,
      occurredAt: ev.occurredAt ? new Date(ev.occurredAt) : undefined,
    };
    const p = ev.payload as Record<string, unknown>;

    if (ev.entityType === 'profile') {
      return this.profiles.upsertForUser(userId, p, ctx);
    }

    if (ev.entityType === 'body_log') {
      if (ev.op === 'delete') {
        return this.bodyLogs.remove(userId, String(p.id), ctx);
      }
      return this.bodyLogs.upsert(userId, p as never, ctx);
    }

    if (ev.entityType === 'workout_session') {
      if (ev.op === 'create') {
        return this.workouts.createSession(userId, p as never, ctx);
      }
      if (ev.op === 'update') {
        return this.workouts.updateSession(
          userId,
          String(p.id),
          p as never,
          ctx,
        );
      }
    }

    if (ev.entityType === 'workout_set') {
      if (ev.op === 'create') {
        return this.workouts.addSets(
          userId,
          String(p.sessionId),
          { sets: (p.sets as never) ?? [] },
          ctx,
        );
      }
      if (ev.op === 'update') {
        return this.workouts.updateSet(userId, String(p.id), p as never, ctx);
      }
      if (ev.op === 'delete') {
        return this.workouts.removeSet(userId, String(p.id), ctx);
      }
    }

    return Promise.reject(new Error(`unsupported ${ev.entityType}/${ev.op}`));
  }
}
