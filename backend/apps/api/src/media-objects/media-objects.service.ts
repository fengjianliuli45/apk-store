import {
  Injectable,
  NotFoundException,
  PayloadTooLargeException,
  UnprocessableEntityException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AllConfigType } from '../config/config.type';
import { newId } from '../common/id/uuid';
import { MediaObjectRepository } from './infrastructure/persistence/media-object.repository';
import { MediaObject, MediaPurpose } from './domain/media-object';
import { StorageService } from './storage/storage.service';
import { RequestUploadDto } from './dto/request-upload.dto';

type PurposeRule = { contentTypes: string[]; maxSize: number };

const MB = 1024 * 1024;
const IMAGE_TYPES = ['image/jpeg', 'image/png', 'image/webp'];

const PURPOSE_RULES: Record<MediaPurpose, PurposeRule> = {
  avatar: { contentTypes: IMAGE_TYPES, maxSize: 5 * MB },
  post: { contentTypes: IMAGE_TYPES, maxSize: 15 * MB },
  progress_photo: { contentTypes: IMAGE_TYPES, maxSize: 15 * MB },
  chat: { contentTypes: IMAGE_TYPES, maxSize: 15 * MB },
};

const EXT_BY_TYPE: Record<string, string> = {
  'image/jpeg': 'jpg',
  'image/png': 'png',
  'image/webp': 'webp',
};

export type UploadTicket = {
  mediaId: string;
  uploadUrl: string;
  storageKey: string;
  expiresIn: number;
};

export type MediaWithUrl = {
  media: MediaObject;
  url: string;
};

@Injectable()
export class MediaObjectsService {
  constructor(
    private readonly repo: MediaObjectRepository,
    private readonly storage: StorageService,
    private readonly configService: ConfigService<AllConfigType>,
  ) {}

  async requestUpload(
    userId: number,
    dto: RequestUploadDto,
  ): Promise<UploadTicket> {
    const rule = PURPOSE_RULES[dto.purpose as MediaPurpose];
    if (!rule) {
      throw new UnprocessableEntityException({
        errors: { purpose: 'unsupported' },
      });
    }
    if (!rule.contentTypes.includes(dto.contentType)) {
      throw new UnprocessableEntityException({
        errors: { contentType: 'unsupported' },
      });
    }
    if (dto.declaredSize <= 0) {
      throw new UnprocessableEntityException({
        errors: { declaredSize: 'invalid' },
      });
    }
    if (dto.declaredSize > rule.maxSize) {
      throw new PayloadTooLargeException({
        errors: { declaredSize: `max:${rule.maxSize}` },
      });
    }

    const ext = EXT_BY_TYPE[dto.contentType];
    const storageKey = `${userId}/${dto.purpose}/${newId()}.${ext}`;
    const ttlSeconds = this.configService.getOrThrow(
      'media.uploadUrlTtlSeconds',
      { infer: true },
    );

    const uploadUrl = await this.storage.presignPut({
      key: storageKey,
      contentType: dto.contentType,
      maxSize: rule.maxSize,
      ttlSeconds,
    });

    const media = await this.repo.create({
      userId,
      purpose: dto.purpose as MediaPurpose,
      storageKey,
      contentType: dto.contentType,
      declaredSize: dto.declaredSize,
      actualSize: null,
      status: 'pending',
      moderationStatus: 'pending',
    });

    return { mediaId: media.id, uploadUrl, storageKey, expiresIn: ttlSeconds };
  }

  async completeUpload(userId: number, mediaId: string): Promise<MediaObject> {
    const media = await this.ownedOrFail(userId, mediaId);
    if (media.status === 'ready') {
      return media;
    }

    const head = await this.storage.head(media.storageKey);
    if (!head) {
      throw new UnprocessableEntityException({
        errors: { upload: 'notFound' },
      });
    }

    const rule = PURPOSE_RULES[media.purpose];
    if (rule && head.size > rule.maxSize) {
      await this.repo.update(media.id, { status: 'rejected' });
      throw new PayloadTooLargeException({
        errors: { upload: `max:${rule.maxSize}` },
      });
    }
    if (head.contentType && head.contentType !== media.contentType) {
      await this.repo.update(media.id, { status: 'rejected' });
      throw new UnprocessableEntityException({
        errors: { contentType: 'mismatch' },
      });
    }

    // TODO(§9.5): 在这里向 worker 投一个内容审核任务；结果回写 moderationStatus。
    const updated = await this.repo.update(media.id, {
      status: 'ready',
      actualSize: head.size,
    });
    return updated ?? media;
  }

  async getWithUrl(userId: number, mediaId: string): Promise<MediaWithUrl> {
    const media = await this.ownedOrFail(userId, mediaId);
    const ttl = this.configService.getOrThrow('media.readUrlTtlSeconds', {
      infer: true,
    });
    const url = await this.storage.presignGet(media.storageKey, ttl);
    return { media, url };
  }

  /** 供其它模块（social / chat）确认一个 media 属于该用户且已 ready。 */
  async assertUsable(userId: number, mediaId: string): Promise<MediaObject> {
    const media = await this.ownedOrFail(userId, mediaId);
    if (media.status !== 'ready') {
      throw new UnprocessableEntityException({
        errors: { media: 'notReady' },
      });
    }
    return media;
  }

  private async ownedOrFail(
    userId: number,
    mediaId: string,
  ): Promise<MediaObject> {
    const media = await this.repo.findById(mediaId);
    if (!media || media.userId !== userId) {
      throw new NotFoundException({ errors: { media: 'notFound' } });
    }
    return media;
  }
}
