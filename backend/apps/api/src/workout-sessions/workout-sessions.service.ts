import { Injectable, NotFoundException } from '@nestjs/common';
import { WorkoutSessionRepository } from './infrastructure/persistence/workout-session.repository';
import { WorkoutSetRepository } from '../workout-sets/infrastructure/persistence/workout-set.repository';
import {
  WorkoutSession,
  WorkoutSessionWithSets,
} from './domain/workout-session';
import { WorkoutSet } from '../workout-sets/domain/workout-set';
import { CursorPage } from '../common/pagination/cursor';
import { SyncEmitterService } from '../sync-events/sync-emitter.service';
import { SyncOp } from '../sync-events/domain/sync-event';
import { CreateWorkoutSessionDto } from './dto/create-workout-session.dto';
import { UpdateWorkoutSessionDto } from './dto/update-workout-session.dto';
import { AddSetsDto } from './dto/add-sets.dto';
import { UpdateSetDto } from './dto/update-set.dto';

/** 通过 /sync/batch 进来的写操作带上客户端事件上下文，用于幂等 + 保留原始时间。 */
export type WriteContext = {
  clientEventId?: string | null;
  occurredAt?: Date;
};

@Injectable()
export class WorkoutSessionsService {
  constructor(
    private readonly sessionRepository: WorkoutSessionRepository,
    private readonly setRepository: WorkoutSetRepository,
    private readonly sync: SyncEmitterService,
  ) {}

  async createSession(
    userId: number,
    dto: CreateWorkoutSessionDto,
    ctx?: WriteContext,
  ): Promise<WorkoutSession> {
    const status = dto.status ?? 'in_progress';
    const session = await this.sessionRepository.create({
      userId,
      planVersionId: dto.planVersionId ?? null,
      planDayIndex: dto.planDayIndex ?? null,
      sessionType: dto.sessionType,
      scheduledDate: dto.scheduledDate ?? null,
      status: status as WorkoutSession['status'],
      startedAt: status === 'in_progress' ? new Date() : null,
      completedAt: status === 'completed' ? new Date() : null,
      notes: null,
    });
    await this.emit(
      userId,
      'workout_session',
      session.id,
      'create',
      session,
      ctx,
    );
    return session;
  }

  async getSession(
    userId: number,
    id: string,
  ): Promise<WorkoutSessionWithSets> {
    const session = await this.ownedSessionOrFail(userId, id);
    const sets = await this.setRepository.findBySessionId(id);
    return { session, sets };
  }

  listSessions(
    userId: number,
    limit: number,
    cursor?: string | null,
  ): Promise<CursorPage<WorkoutSession>> {
    return this.sessionRepository.listByUser(userId, limit, cursor);
  }

  async updateSession(
    userId: number,
    id: string,
    dto: UpdateWorkoutSessionDto,
    ctx?: WriteContext,
  ): Promise<WorkoutSession> {
    const session = await this.ownedSessionOrFail(userId, id);

    const patch: Partial<WorkoutSession> = {};
    if (dto.notes !== undefined) {
      patch.notes = dto.notes;
    }
    if (dto.status !== undefined) {
      patch.status = dto.status as WorkoutSession['status'];
      if (dto.status === 'completed' && !session.completedAt) {
        patch.completedAt = new Date();
      }
      if (dto.status === 'in_progress' && !session.startedAt) {
        patch.startedAt = new Date();
      }
    }

    const updated = (await this.sessionRepository.update(id, patch)) ?? session;
    await this.emit(userId, 'workout_session', id, 'update', updated, ctx);
    return updated;
  }

  async addSets(
    userId: number,
    sessionId: string,
    dto: AddSetsDto,
    ctx?: WriteContext,
  ): Promise<WorkoutSet[]> {
    await this.ownedSessionOrFail(userId, sessionId);
    const created = await this.setRepository.createMany(
      dto.sets.map((s) => ({
        sessionId,
        exerciseKey: s.exerciseKey,
        exerciseName: s.exerciseName,
        setIndex: s.setIndex,
        reps: s.reps ?? null,
        weightKg: s.weightKg ?? null,
        rir: s.rir ?? null,
        isWarmup: s.isWarmup ?? false,
        completedAt: new Date(),
      })),
    );
    await this.emit(
      userId,
      'workout_set',
      sessionId,
      'create',
      { sessionId, sets: created },
      ctx,
    );
    return created;
  }

  async updateSet(
    userId: number,
    setId: string,
    dto: UpdateSetDto,
    ctx?: WriteContext,
  ): Promise<WorkoutSet> {
    const set = await this.ownedSetOrFail(userId, setId);
    const patch: Partial<WorkoutSet> = {};
    for (const key of ['reps', 'weightKg', 'rir', 'isWarmup'] as const) {
      if (dto[key] !== undefined) {
        (patch as Record<string, unknown>)[key] = dto[key];
      }
    }
    const updated = (await this.setRepository.update(setId, patch)) ?? set;
    await this.emit(
      userId,
      'workout_set',
      set.sessionId,
      'update',
      updated,
      ctx,
    );
    return updated;
  }

  async removeSet(
    userId: number,
    setId: string,
    ctx?: WriteContext,
  ): Promise<void> {
    const set = await this.ownedSetOrFail(userId, setId);
    await this.setRepository.remove(setId);
    await this.emit(
      userId,
      'workout_set',
      set.sessionId,
      'delete',
      { id: setId, sessionId: set.sessionId },
      ctx,
    );
  }

  private emit(
    userId: number,
    entityType: string,
    entityId: string | null,
    op: SyncOp,
    payload: unknown,
    ctx?: WriteContext,
  ) {
    return this.sync.emit({
      userId,
      entityType,
      entityId,
      op,
      payload: payload as Record<string, unknown>,
      clientEventId: ctx?.clientEventId ?? null,
      occurredAt: ctx?.occurredAt,
    });
  }

  private async ownedSessionOrFail(
    userId: number,
    id: string,
  ): Promise<WorkoutSession> {
    const session = await this.sessionRepository.findById(id);
    if (!session || session.userId !== userId) {
      throw new NotFoundException({ errors: { session: 'notFound' } });
    }
    return session;
  }

  private async ownedSetOrFail(
    userId: number,
    setId: string,
  ): Promise<WorkoutSet> {
    const set = await this.setRepository.findById(setId);
    if (!set) {
      throw new NotFoundException({ errors: { set: 'notFound' } });
    }
    await this.ownedSessionOrFail(userId, set.sessionId);
    return set;
  }
}
