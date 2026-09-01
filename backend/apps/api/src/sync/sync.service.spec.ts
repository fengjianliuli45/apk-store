import { SyncService } from './sync.service';
import { SyncEmitterService } from '../sync-events/sync-emitter.service';
import { SyncEvent } from '../sync-events/domain/sync-event';
import { SyncEventRepository } from '../sync-events/infrastructure/persistence/sync-event.repository';
import { WorkoutSessionsService } from '../workout-sessions/workout-sessions.service';
import { WorkoutSession } from '../workout-sessions/domain/workout-session';
import { WorkoutSessionRepository } from '../workout-sessions/infrastructure/persistence/workout-session.repository';
import { WorkoutSet } from '../workout-sets/domain/workout-set';
import { WorkoutSetRepository } from '../workout-sets/infrastructure/persistence/workout-set.repository';
import { ProfilesService } from '../profiles/profiles.service';
import { Profile } from '../profiles/domain/profile';
import { ProfileRepository } from '../profiles/infrastructure/persistence/profile.repository';
import { CursorPage } from '../common/pagination/cursor';

class MemSyncEventRepo implements SyncEventRepository {
  rows: SyncEvent[] = [];

  append(data: Omit<SyncEvent, 'id' | 'serverSeq' | 'createdAt'>) {
    if (data.clientEventId) {
      const existing = this.rows.find(
        (r) =>
          r.userId === data.userId && r.clientEventId === data.clientEventId,
      );
      if (existing) {
        return Promise.resolve({ event: existing, deduped: true });
      }
    }
    const seq =
      this.rows
        .filter((r) => r.userId === data.userId)
        .reduce((m, r) => Math.max(m, r.serverSeq), 0) + 1;
    const event: SyncEvent = {
      ...(data as SyncEvent),
      id: `e-${this.rows.length + 1}`,
      serverSeq: seq,
      createdAt: new Date(),
    };
    this.rows.push(event);
    return Promise.resolve({ event, deduped: false });
  }

  findByUserAndClientEventId(userId: number, clientEventId: string) {
    return Promise.resolve(
      this.rows.find(
        (r) => r.userId === userId && r.clientEventId === clientEventId,
      ) ?? null,
    );
  }

  listSince(userId: number, afterSeq: number, limit: number) {
    return Promise.resolve(
      this.rows
        .filter((r) => r.userId === userId && r.serverSeq > afterSeq)
        .sort((a, b) => a.serverSeq - b.serverSeq)
        .slice(0, limit),
    );
  }

  maxSeq(userId: number) {
    return Promise.resolve(
      this.rows
        .filter((r) => r.userId === userId)
        .reduce((m, r) => Math.max(m, r.serverSeq), 0),
    );
  }
}

class MemSessionRepo implements WorkoutSessionRepository {
  rows: WorkoutSession[] = [];
  create(d: Omit<WorkoutSession, 'id' | 'createdAt' | 'updatedAt'>) {
    const row: WorkoutSession = {
      ...(d as WorkoutSession),
      id: `s-${this.rows.length + 1}`,
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    this.rows.push(row);
    return Promise.resolve(row);
  }
  findById(id: string) {
    return Promise.resolve(this.rows.find((r) => r.id === id) ?? null);
  }
  listByUser(userId: number): Promise<CursorPage<WorkoutSession>> {
    return Promise.resolve({
      data: this.rows.filter((r) => r.userId === userId),
      nextCursor: null,
    });
  }
  update(id: string, p: Partial<WorkoutSession>) {
    const row = this.rows.find((r) => r.id === id);
    if (!row) return Promise.resolve(null);
    Object.assign(row, p);
    return Promise.resolve(row);
  }
}

class MemSetRepo implements WorkoutSetRepository {
  rows: WorkoutSet[] = [];
  createMany(data: Omit<WorkoutSet, 'id' | 'createdAt'>[]) {
    const created = data.map((d, i) => ({
      ...(d as WorkoutSet),
      id: `set-${this.rows.length + i + 1}`,
      createdAt: new Date(),
    }));
    this.rows.push(...created);
    return Promise.resolve(created);
  }
  findBySessionId(sessionId: string) {
    return Promise.resolve(this.rows.filter((r) => r.sessionId === sessionId));
  }
  findById(id: string) {
    return Promise.resolve(this.rows.find((r) => r.id === id) ?? null);
  }
  update(id: string, p: Partial<WorkoutSet>) {
    const row = this.rows.find((r) => r.id === id);
    if (!row) return Promise.resolve(null);
    Object.assign(row, p);
    return Promise.resolve(row);
  }
  remove(id: string) {
    this.rows = this.rows.filter((r) => r.id !== id);
    return Promise.resolve();
  }
}

class MemProfileRepo implements ProfileRepository {
  rows: Profile[] = [];
  create(d: Omit<Profile, 'id' | 'createdAt' | 'updatedAt'>) {
    const row: Profile = {
      ...(d as Profile),
      id: `p-${this.rows.length + 1}`,
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    this.rows.push(row);
    return Promise.resolve(row);
  }
  findByUserId(userId: number) {
    return Promise.resolve(this.rows.find((r) => r.userId === userId) ?? null);
  }
  update(id: string, p: Partial<Profile>) {
    const row = this.rows.find((r) => r.id === id);
    if (!row) return Promise.resolve(null);
    Object.assign(row, p);
    return Promise.resolve(row);
  }
  remove(id: string) {
    this.rows = this.rows.filter((r) => r.id !== id);
    return Promise.resolve();
  }
}

describe('SyncService (integration with in-memory repos)', () => {
  let eventRepo: MemSyncEventRepo;
  let service: SyncService;

  beforeEach(() => {
    eventRepo = new MemSyncEventRepo();
    const emitter = new SyncEmitterService(eventRepo);
    const workouts = new WorkoutSessionsService(
      new MemSessionRepo(),
      new MemSetRepo(),
      emitter,
    );
    const profiles = new ProfilesService(new MemProfileRepo(), emitter);
    const bodyLogs = {
      upsert: jest.fn().mockResolvedValue({ id: 'bl-1' }),
      remove: jest.fn().mockResolvedValue(undefined),
    } as unknown as import('../body-logs/body-logs.service').BodyLogsService;
    service = new SyncService(eventRepo, workouts, profiles, bodyLogs);
  });

  it('should apply a batch and advance the cursor', async () => {
    const res = await service.pushBatch(1, {
      events: [
        {
          clientEventId: 'c1',
          entityType: 'profile',
          op: 'update',
          payload: { goal: 'hypertrophy' },
        },
        {
          clientEventId: 'c2',
          entityType: 'workout_session',
          op: 'create',
          payload: { sessionType: 'strength' },
        },
      ],
    });
    expect(res.results.map((r) => r.status)).toEqual(['applied', 'applied']);
    expect(res.syncCursor).toBe(2);
    expect(res.results[0].serverSeq).toBe(1);
  });

  it('should dedupe a replayed clientEventId', async () => {
    const ev = {
      clientEventId: 'c1',
      entityType: 'profile' as const,
      op: 'update' as const,
      payload: { goal: 'strength' },
    };
    await service.pushBatch(1, { events: [ev] });
    const res = await service.pushBatch(1, { events: [ev] });
    expect(res.results[0].status).toBe('duplicate');
    expect(res.results[0].serverSeq).toBe(1);
    expect(eventRepo.rows).toHaveLength(1);
  });

  it('should reject an unsupported entity/op without aborting the batch', async () => {
    const res = await service.pushBatch(1, {
      events: [
        {
          clientEventId: 'c1',
          entityType: 'workout_session',
          op: 'delete',
          payload: { id: 'x' },
        },
        {
          clientEventId: 'c2',
          entityType: 'profile',
          op: 'create',
          payload: { goal: 'fat_loss' },
        },
      ],
    });
    expect(res.results[0].status).toBe('rejected');
    expect(res.results[1].status).toBe('applied');
  });

  it('should pull only changes after the cursor', async () => {
    await service.pushBatch(1, {
      events: [
        {
          clientEventId: 'a',
          entityType: 'profile',
          op: 'update',
          payload: {},
        },
        {
          clientEventId: 'b',
          entityType: 'workout_session',
          op: 'create',
          payload: { sessionType: 'strength' },
        },
      ],
    });
    const page = await service.pullChanges(1, 1, 10);
    expect(page.events).toHaveLength(1);
    expect(page.events[0].serverSeq).toBe(2);
    expect(page.hasMore).toBe(false);
    expect(page.nextCursor).toBe(2);
  });

  it('should not leak another users changes', async () => {
    await service.pushBatch(1, {
      events: [
        {
          clientEventId: 'a',
          entityType: 'profile',
          op: 'update',
          payload: {},
        },
      ],
    });
    const page = await service.pullChanges(2, 0, 10);
    expect(page.events).toHaveLength(0);
  });

  it('should page with hasMore when results exceed the limit', async () => {
    await service.pushBatch(1, {
      events: [1, 2, 3].map((n) => ({
        clientEventId: `c${n}`,
        entityType: 'profile' as const,
        op: 'update' as const,
        payload: { n },
      })),
    });
    const page = await service.pullChanges(1, 0, 2);
    expect(page.events).toHaveLength(2);
    expect(page.hasMore).toBe(true);
    expect(page.nextCursor).toBe(2);
  });
});
