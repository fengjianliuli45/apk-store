import { NotFoundException } from '@nestjs/common';
import { ProfilesService } from './profiles.service';
import { Profile } from './domain/profile';
import { ProfileRepository } from './infrastructure/persistence/profile.repository';
import { SyncEmitterService } from '../sync-events/sync-emitter.service';

const fakeSync = {
  emit: () => Promise.resolve(null),
  cursor: () => Promise.resolve(0),
} as unknown as SyncEmitterService;

class FakeProfileRepository implements ProfileRepository {
  rows: Profile[] = [];

  create(data: Omit<Profile, 'id' | 'createdAt' | 'updatedAt'>) {
    const row: Profile = {
      ...(data as Profile),
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

  update(id: string, payload: Partial<Profile>) {
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

describe('ProfilesService', () => {
  let repo: FakeProfileRepository;
  let service: ProfilesService;

  beforeEach(() => {
    repo = new FakeProfileRepository();
    service = new ProfilesService(repo, fakeSync);
  });

  it('should create a profile on first upsert', async () => {
    const p = await service.upsertForUser(7, {
      goal: 'hypertrophy',
      equipment: ['dumbbell'],
    });
    expect(p.userId).toBe(7);
    expect(p.goal).toBe('hypertrophy');
    expect(p.equipment).toEqual(['dumbbell']);
    expect(p.dietaryRestrictions).toEqual([]);
  });

  it('should partially patch an existing profile', async () => {
    await service.upsertForUser(7, { goal: 'hypertrophy', heightCm: 175 });
    const p = await service.upsertForUser(7, { goal: 'fat_loss' });
    expect(p.goal).toBe('fat_loss');
    expect(p.heightCm).toBe(175);
    expect(repo.rows).toHaveLength(1);
  });

  it('should stamp a consent timestamp when bodyDataConsent is true', async () => {
    const p = await service.upsertForUser(7, {
      bodyDataConsent: true,
      bodyDataConsentVersion: '2026-01',
    });
    expect(p.bodyDataConsentAt).toBeInstanceOf(Date);
    expect(p.bodyDataConsentVersion).toBe('2026-01');
  });

  it('should clear consent when bodyDataConsent is false', async () => {
    await service.upsertForUser(7, { bodyDataConsent: true });
    const p = await service.upsertForUser(7, { bodyDataConsent: false });
    expect(p.bodyDataConsentAt).toBeNull();
  });

  it('should throw when reading a profile that was never created', async () => {
    await expect(service.getByUserIdOrFail(99)).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });

  it('should not treat an omitted field as a clear', async () => {
    await service.upsertForUser(7, { injuriesText: '右肩疼' });
    const p = await service.upsertForUser(7, { goal: 'strength' });
    expect(p.injuriesText).toBe('右肩疼');
  });
});
