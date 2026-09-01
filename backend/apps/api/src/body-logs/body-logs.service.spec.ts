import { NotFoundException } from '@nestjs/common';
import { BodyLogsService } from './body-logs.service';
import { BodyLog } from './domain/body-log';
import { BodyLogRepository } from './infrastructure/persistence/body-log.repository';
import { CursorPage } from '../common/pagination/cursor';
import { SyncEmitterService } from '../sync-events/sync-emitter.service';

class MemRepo implements BodyLogRepository {
  rows: BodyLog[] = [];
  upsert(d: Omit<BodyLog, 'id' | 'createdAt' | 'updatedAt'>) {
    const hit = this.rows.find(
      (r) => r.userId === d.userId && r.measuredOn === d.measuredOn,
    );
    if (hit) {
      Object.assign(hit, d, { updatedAt: new Date() });
      return Promise.resolve(hit);
    }
    const row: BodyLog = {
      ...(d as BodyLog),
      id: `bl-${this.rows.length + 1}`,
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    this.rows.push(row);
    return Promise.resolve(row);
  }
  findById(id: string) {
    return Promise.resolve(this.rows.find((r) => r.id === id) ?? null);
  }
  remove(id: string) {
    this.rows = this.rows.filter((r) => r.id !== id);
    return Promise.resolve();
  }
  list(userId: number): Promise<CursorPage<BodyLog>> {
    return Promise.resolve({
      data: this.rows.filter((r) => r.userId === userId),
      nextCursor: null,
    });
  }
}

const fakeSync = {
  emit: jest.fn().mockResolvedValue(null),
} as unknown as SyncEmitterService;

describe('BodyLogsService', () => {
  let repo: MemRepo;
  let service: BodyLogsService;

  beforeEach(() => {
    repo = new MemRepo();
    (fakeSync.emit as jest.Mock).mockClear();
    service = new BodyLogsService(repo, fakeSync);
  });

  it('should upsert one row per user per date', async () => {
    await service.upsert(1, { measuredOn: '2026-09-01', weightKg: 72.4 });
    const again = await service.upsert(1, {
      measuredOn: '2026-09-01',
      weightKg: 72.0,
      waistCm: 80,
    });
    expect(repo.rows).toHaveLength(1);
    expect(again.weightKg).toBe(72.0);
    expect(again.waistCm).toBe(80);
  });

  it('should emit a sync event on upsert', async () => {
    await service.upsert(1, { measuredOn: '2026-09-01', weightKg: 72 });
    expect(fakeSync.emit).toHaveBeenCalledWith(
      expect.objectContaining({ entityType: 'body_log', op: 'update' }),
    );
  });

  it('should 404 deleting another users log', async () => {
    const log = await service.upsert(1, { measuredOn: '2026-09-01' });
    await expect(service.remove(2, log.id)).rejects.toBeInstanceOf(
      NotFoundException,
    );
    await expect(service.remove(1, log.id)).resolves.toBeUndefined();
    expect(repo.rows).toHaveLength(0);
  });
});
