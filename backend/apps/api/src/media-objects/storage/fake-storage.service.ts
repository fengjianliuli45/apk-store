import { Injectable } from '@nestjs/common';
import { HeadResult, PresignPutInput, StorageService } from './storage.service';

/**
 * 内存假存储：开发 / 测试用。presignPut 返回一个假 URL；
 * 测试里用 `simulateUpload` 模拟客户端直传完成。
 */
@Injectable()
export class FakeStorageService extends StorageService {
  private objects = new Map<string, HeadResult>();

  presignPut(input: PresignPutInput): Promise<string> {
    return Promise.resolve(
      `https://fake-storage.local/put/${encodeURIComponent(input.key)}?ct=${
        input.contentType
      }&max=${input.maxSize}&ttl=${input.ttlSeconds}`,
    );
  }

  presignGet(key: string, ttlSeconds: number): Promise<string> {
    return Promise.resolve(
      `https://fake-storage.local/get/${encodeURIComponent(
        key,
      )}?ttl=${ttlSeconds}`,
    );
  }

  head(key: string): Promise<HeadResult | null> {
    return Promise.resolve(this.objects.get(key) ?? null);
  }

  delete(key: string): Promise<void> {
    this.objects.delete(key);
    return Promise.resolve();
  }

  /** 仅测试：登记一个"已上传"的对象。 */
  simulateUpload(key: string, size: number, contentType: string): void {
    this.objects.set(key, { size, contentType });
  }
}
