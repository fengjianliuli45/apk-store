import { NotFoundException } from '@nestjs/common';
import { TrainingPlansService } from './training-plans.service';
import { TrainingPlan } from './domain/training-plan';
import { TrainingPlanRepository } from './infrastructure/persistence/training-plan.repository';
import { PlanVersion } from '../plan-versions/domain/plan-version';
import { PlanVersionRepository } from '../plan-versions/infrastructure/persistence/plan-version.repository';
import { CursorPage } from '../common/pagination/cursor';

class FakePlanRepo implements TrainingPlanRepository {
  rows: TrainingPlan[] = [];
  create(data: Omit<TrainingPlan, 'id' | 'createdAt' | 'updatedAt'>) {
    const row: TrainingPlan = {
      ...(data as TrainingPlan),
      id: `plan-${this.rows.length + 1}`,
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    this.rows.push(row);
    return Promise.resolve(row);
  }
  findById(id: string) {
    return Promise.resolve(this.rows.find((r) => r.id === id) ?? null);
  }
  findActiveByUserId(userId: number) {
    return Promise.resolve(
      this.rows.find((r) => r.userId === userId && r.status === 'active') ??
        null,
    );
  }
  update(id: string, payload: Partial<TrainingPlan>) {
    const row = this.rows.find((r) => r.id === id);
    if (!row) return Promise.resolve(null);
    Object.assign(row, payload);
    return Promise.resolve(row);
  }
}

class FakeVersionRepo implements PlanVersionRepository {
  rows: PlanVersion[] = [];
  create(data: Omit<PlanVersion, 'id' | 'createdAt'>) {
    const row: PlanVersion = {
      ...(data as PlanVersion),
      id: `v-${this.rows.length + 1}`,
      createdAt: new Date(),
    };
    this.rows.push(row);
    return Promise.resolve(row);
  }
  findById(id: string) {
    return Promise.resolve(this.rows.find((r) => r.id === id) ?? null);
  }
  listByPlan(planId: string): Promise<CursorPage<PlanVersion>> {
    return Promise.resolve({
      data: this.rows.filter((r) => r.planId === planId),
      nextCursor: null,
    });
  }
}

const dto = (over: Partial<Record<string, unknown>> = {}) => ({
  plannerVersion: '1.8',
  generatedBy: 'dart',
  inputSnapshot: { goal: 'hypertrophy' },
  planJson: { version: '1.8', days: [] },
  ...over,
});

describe('TrainingPlansService', () => {
  let plans: FakePlanRepo;
  let versions: FakeVersionRepo;
  let service: TrainingPlansService;

  beforeEach(() => {
    plans = new FakePlanRepo();
    versions = new FakeVersionRepo();
    service = new TrainingPlansService(plans, versions);
  });

  it('should create a plan with version 1 on first save', async () => {
    const res = await service.savePlan(1, dto());
    expect(res.plan.currentVersionNumber).toBe(1);
    expect(res.currentVersion.versionNumber).toBe(1);
    expect(res.plan.currentVersionId).toBe(res.currentVersion.id);
  });

  it('should append a new version to the same plan on later saves', async () => {
    await service.savePlan(1, dto());
    const res = await service.savePlan(1, dto({ changeReason: 'check-in' }));
    expect(res.plan.currentVersionNumber).toBe(2);
    expect(res.currentVersion.versionNumber).toBe(2);
    expect(plans.rows).toHaveLength(1);
    expect(versions.rows).toHaveLength(2);
    expect(versions.rows[0].versionNumber).toBe(1); // v1 unchanged
  });

  it('should return the current version', async () => {
    await service.savePlan(1, dto());
    await service.savePlan(1, dto());
    const cur = await service.getCurrent(1);
    expect(cur.currentVersion.versionNumber).toBe(2);
  });

  it('should 404 getCurrent when the user has no active plan', async () => {
    await expect(service.getCurrent(1)).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });

  it('should not leak another users plan version', async () => {
    const res = await service.savePlan(1, dto());
    await expect(
      service.getVersion(2, res.currentVersion.id),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('should archive the active plan', async () => {
    await service.savePlan(1, dto());
    const archived = await service.archiveCurrent(1);
    expect(archived.status).toBe('archived');
    await expect(service.getCurrent(1)).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });

  it('should start a fresh plan after archiving', async () => {
    await service.savePlan(1, dto());
    await service.archiveCurrent(1);
    const res = await service.savePlan(1, dto());
    expect(res.plan.currentVersionNumber).toBe(1);
    expect(plans.rows).toHaveLength(2);
  });
});
