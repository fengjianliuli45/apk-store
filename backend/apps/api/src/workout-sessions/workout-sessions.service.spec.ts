import { NotFoundException } from '@nestjs/common';
import { WorkoutSessionsService } from './workout-sessions.service';
import { WorkoutSession } from './domain/workout-session';
import { WorkoutSessionRepository } from './infrastructure/persistence/workout-session.repository';
import { WorkoutSet } from '../workout-sets/domain/workout-set';
import { WorkoutSetRepository } from '../workout-sets/infrastructure/persistence/workout-set.repository';
import { CursorPage } from '../common/pagination/cursor';

class FakeSessionRepo implements WorkoutSessionRepository {
  rows: WorkoutSession[] = [];
  create(data: Omit<WorkoutSession, 'id' | 'createdAt' | 'updatedAt'>) {
    const row: WorkoutSession = {
      ...(data as WorkoutSession),
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
  update(id: string, payload: Partial<WorkoutSession>) {
    const row = this.rows.find((r) => r.id === id);
    if (!row) return Promise.resolve(null);
    Object.assign(row, payload);
    return Promise.resolve(row);
  }
}

class FakeSetRepo implements WorkoutSetRepository {
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
  update(id: string, payload: Partial<WorkoutSet>) {
    const row = this.rows.find((r) => r.id === id);
    if (!row) return Promise.resolve(null);
    Object.assign(row, payload);
    return Promise.resolve(row);
  }
  remove(id: string) {
    this.rows = this.rows.filter((r) => r.id !== id);
    return Promise.resolve();
  }
}

describe('WorkoutSessionsService', () => {
  let sessions: FakeSessionRepo;
  let sets: FakeSetRepo;
  let service: WorkoutSessionsService;

  beforeEach(() => {
    sessions = new FakeSessionRepo();
    sets = new FakeSetRepo();
    service = new WorkoutSessionsService(sessions, sets);
  });

  it('should stamp startedAt when a session starts in_progress', async () => {
    const s = await service.createSession(1, { sessionType: 'strength' });
    expect(s.status).toBe('in_progress');
    expect(s.startedAt).toBeInstanceOf(Date);
    expect(s.completedAt).toBeNull();
  });

  it('should append sets to an owned session', async () => {
    const s = await service.createSession(1, { sessionType: 'strength' });
    const added = await service.addSets(1, s.id, {
      sets: [
        {
          exerciseKey: 'horizontal_push',
          exerciseName: '卧推',
          setIndex: 1,
          reps: 8,
          weightKg: 60,
        },
        {
          exerciseKey: 'horizontal_push',
          exerciseName: '卧推',
          setIndex: 2,
          reps: 7,
          weightKg: 60,
        },
      ],
    });
    expect(added).toHaveLength(2);
    const got = await service.getSession(1, s.id);
    expect(got.sets).toHaveLength(2);
  });

  it('should reject set writes to another users session', async () => {
    const s = await service.createSession(1, { sessionType: 'strength' });
    await expect(
      service.addSets(2, s.id, {
        sets: [{ exerciseKey: 'x', exerciseName: 'x', setIndex: 1 }],
      }),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('should stamp completedAt on transition to completed', async () => {
    const s = await service.createSession(1, {
      sessionType: 'strength',
      status: 'planned',
    });
    const done = await service.updateSession(1, s.id, { status: 'completed' });
    expect(done.completedAt).toBeInstanceOf(Date);
  });

  it('should correct a set only for its owner', async () => {
    const s = await service.createSession(1, { sessionType: 'strength' });
    const [set] = await service.addSets(1, s.id, {
      sets: [
        { exerciseKey: 'x', exerciseName: 'x', setIndex: 1, weightKg: 60 },
      ],
    });
    const fixed = await service.updateSet(1, set.id, { weightKg: 62.5 });
    expect(fixed.weightKg).toBe(62.5);
    await expect(
      service.updateSet(2, set.id, { weightKg: 100 }),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('should 404 on an unknown session', async () => {
    await expect(service.getSession(1, 'nope')).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });
});
