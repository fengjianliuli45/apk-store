import {
  NotFoundException,
  PayloadTooLargeException,
  UnprocessableEntityException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { MediaObjectsService } from './media-objects.service';
import { MediaObject } from './domain/media-object';
import { MediaObjectRepository } from './infrastructure/persistence/media-object.repository';
import { FakeStorageService } from './storage/fake-storage.service';

class MemRepo implements MediaObjectRepository {
  rows: MediaObject[] = [];
  create(d: Omit<MediaObject, 'id' | 'createdAt' | 'updatedAt'>) {
    const row: MediaObject = {
      ...(d as MediaObject),
      id: `m-${this.rows.length + 1}`,
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    this.rows.push(row);
    return Promise.resolve(row);
  }
  findById(id: string) {
    return Promise.resolve(this.rows.find((r) => r.id === id) ?? null);
  }
  update(id: string, p: Partial<MediaObject>) {
    const row = this.rows.find((r) => r.id === id);
    if (!row) return Promise.resolve(null);
    Object.assign(row, p);
    return Promise.resolve(row);
  }
}

const config = {
  getOrThrow: (key: string) =>
    key === 'media.uploadUrlTtlSeconds'
      ? 300
      : key === 'media.readUrlTtlSeconds'
        ? 3600
        : undefined,
} as unknown as ConfigService;

describe('MediaObjectsService', () => {
  let repo: MemRepo;
  let storage: FakeStorageService;
  let service: MediaObjectsService;

  beforeEach(() => {
    repo = new MemRepo();
    storage = new FakeStorageService();
    service = new MediaObjectsService(repo, storage, config);
  });

  const req = (over: Partial<Record<string, unknown>> = {}) => ({
    purpose: 'post',
    contentType: 'image/jpeg',
    declaredSize: 200_000,
    ...over,
  });

  it('should scope the storage key by user and purpose', async () => {
    const t = await service.requestUpload(7, req());
    expect(t.storageKey).toMatch(/^7\/post\/[0-9a-f-]+\.jpg$/);
    expect(t.uploadUrl).toContain('fake-storage.local');
    expect(repo.rows[0].status).toBe('pending');
  });

  it('should reject a disallowed content type', async () => {
    await expect(
      service.requestUpload(7, req({ contentType: 'application/pdf' })),
    ).rejects.toBeInstanceOf(UnprocessableEntityException);
  });

  it('should reject an oversized declared size', async () => {
    await expect(
      service.requestUpload(7, req({ declaredSize: 999_000_000 })),
    ).rejects.toBeInstanceOf(PayloadTooLargeException);
  });

  it('should mark ready on complete after a real upload', async () => {
    const t = await service.requestUpload(7, req());
    storage.simulateUpload(t.storageKey, 190_000, 'image/jpeg');
    const done = await service.completeUpload(7, t.mediaId);
    expect(done.status).toBe('ready');
    expect(done.actualSize).toBe(190_000);
  });

  it('should fail complete when nothing was uploaded', async () => {
    const t = await service.requestUpload(7, req());
    await expect(service.completeUpload(7, t.mediaId)).rejects.toBeInstanceOf(
      UnprocessableEntityException,
    );
  });

  it('should reject on complete when the real object exceeds the cap', async () => {
    const t = await service.requestUpload(7, req());
    storage.simulateUpload(t.storageKey, 20 * 1024 * 1024, 'image/jpeg');
    await expect(service.completeUpload(7, t.mediaId)).rejects.toBeInstanceOf(
      PayloadTooLargeException,
    );
    expect(repo.rows[0].status).toBe('rejected');
  });

  it('should reject on content-type mismatch', async () => {
    const t = await service.requestUpload(7, req());
    storage.simulateUpload(t.storageKey, 1000, 'image/png');
    await expect(service.completeUpload(7, t.mediaId)).rejects.toBeInstanceOf(
      UnprocessableEntityException,
    );
  });

  it('should be idempotent on repeated complete', async () => {
    const t = await service.requestUpload(7, req());
    storage.simulateUpload(t.storageKey, 1000, 'image/jpeg');
    await service.completeUpload(7, t.mediaId);
    const again = await service.completeUpload(7, t.mediaId);
    expect(again.status).toBe('ready');
  });

  it('should not expose another users media', async () => {
    const t = await service.requestUpload(7, req());
    await expect(service.getWithUrl(8, t.mediaId)).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });

  it('should gate assertUsable on ready status', async () => {
    const t = await service.requestUpload(7, req());
    await expect(service.assertUsable(7, t.mediaId)).rejects.toBeInstanceOf(
      UnprocessableEntityException,
    );
    storage.simulateUpload(t.storageKey, 1000, 'image/jpeg');
    await service.completeUpload(7, t.mediaId);
    await expect(service.assertUsable(7, t.mediaId)).resolves.toMatchObject({
      status: 'ready',
    });
  });
});
