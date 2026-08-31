import { Injectable } from '@nestjs/common';
import {
  HeadObjectCommand,
  DeleteObjectCommand,
  GetObjectCommand,
  PutObjectCommand,
  S3Client,
} from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { HeadResult, PresignPutInput, StorageService } from './storage.service';
import { MediaConfig } from '../config/media-config.type';

/**
 * S3 兼容存储。`endpoint` 设成阿里云 OSS / 腾讯云 COS 的 S3 网关即可复用
 * （见 config：MEDIA_S3_ENDPOINT）。
 */
@Injectable()
export class S3StorageService extends StorageService {
  private readonly client: S3Client;
  private readonly bucket: string;
  private readonly publicBaseUrl?: string;

  constructor(config: MediaConfig) {
    super();
    this.bucket = config.s3Bucket ?? '';
    this.publicBaseUrl = config.publicBaseUrl;
    this.client = new S3Client({
      region: config.s3Region ?? 'us-east-1',
      endpoint: config.s3Endpoint,
      forcePathStyle: config.s3ForcePathStyle,
      credentials: {
        accessKeyId: config.s3AccessKeyId ?? '',
        secretAccessKey: config.s3SecretAccessKey ?? '',
      },
    });
  }

  presignPut(input: PresignPutInput): Promise<string> {
    const command = new PutObjectCommand({
      Bucket: this.bucket,
      Key: input.key,
      ContentType: input.contentType,
      ContentLength: input.maxSize,
    });
    return getSignedUrl(this.client, command, {
      expiresIn: input.ttlSeconds,
    });
  }

  presignGet(key: string, ttlSeconds: number): Promise<string> {
    if (this.publicBaseUrl) {
      return Promise.resolve(`${this.publicBaseUrl.replace(/\/$/, '')}/${key}`);
    }
    const command = new GetObjectCommand({ Bucket: this.bucket, Key: key });
    return getSignedUrl(this.client, command, { expiresIn: ttlSeconds });
  }

  async head(key: string): Promise<HeadResult | null> {
    try {
      const res = await this.client.send(
        new HeadObjectCommand({ Bucket: this.bucket, Key: key }),
      );
      return {
        size: res.ContentLength ?? 0,
        contentType: res.ContentType ?? null,
      };
    } catch {
      return null;
    }
  }

  async delete(key: string): Promise<void> {
    await this.client.send(
      new DeleteObjectCommand({ Bucket: this.bucket, Key: key }),
    );
  }
}
