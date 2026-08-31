import { Injectable, NotFoundException } from '@nestjs/common';
import { WorkoutSessionRepository } from './infrastructure/persistence/workout-session.repository';
import { WorkoutSetRepository } from '../workout-sets/infrastructure/persistence/workout-set.repository';
import {
  WorkoutSession,
  WorkoutSessionWithSets,
} from './domain/workout-session';
import { WorkoutSet } from '../workout-sets/domain/workout-set';
import { CursorPage } from '../common/pagination/cursor';
import { CreateWorkoutSessionDto } from './dto/create-workout-session.dto';
import { UpdateWorkoutSessionDto } from './dto/update-workout-session.dto';
import { AddSetsDto } from './dto/add-sets.dto';
import { UpdateSetDto } from './dto/update-set.dto';

@Injectable()
export class WorkoutSessionsService {
  constructor(
    private readonly sessionRepository: WorkoutSessionRepository,
    private readonly setRepository: WorkoutSetRepository,
  ) {}

  async createSession(
    userId: number,
    dto: CreateWorkoutSessionDto,
  ): Promise<WorkoutSession> {
    const status = dto.status ?? 'in_progress';
    return this.sessionRepository.create({
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

    const updated = await this.sessionRepository.update(id, patch);
    return updated ?? session;
  }

  async addSets(
    userId: number,
    sessionId: string,
    dto: AddSetsDto,
  ): Promise<WorkoutSet[]> {
    await this.ownedSessionOrFail(userId, sessionId);
    return this.setRepository.createMany(
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
  }

  async updateSet(
    userId: number,
    setId: string,
    dto: UpdateSetDto,
  ): Promise<WorkoutSet> {
    const set = await this.ownedSetOrFail(userId, setId);
    const patch: Partial<WorkoutSet> = {};
    for (const key of ['reps', 'weightKg', 'rir', 'isWarmup'] as const) {
      if (dto[key] !== undefined) {
        (patch as Record<string, unknown>)[key] = dto[key];
      }
    }
    const updated = await this.setRepository.update(setId, patch);
    return updated ?? set;
  }

  async removeSet(userId: number, setId: string): Promise<void> {
    await this.ownedSetOrFail(userId, setId);
    await this.setRepository.remove(setId);
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
