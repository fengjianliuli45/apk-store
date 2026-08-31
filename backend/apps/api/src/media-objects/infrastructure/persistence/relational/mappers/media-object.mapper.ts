import {
  MediaObject,
  MediaPurpose,
  MediaStatus,
} from '../../../../domain/media-object';
import { MediaObjectEntity } from '../entities/media-object.entity';

export class MediaObjectMapper {
  static toDomain(raw: MediaObjectEntity): MediaObject {
    const domain = new MediaObject();
    domain.id = raw.id;
    domain.userId = raw.userId;
    domain.purpose = raw.purpose as MediaPurpose;
    domain.storageKey = raw.storageKey;
    domain.contentType = raw.contentType;
    domain.declaredSize = Number(raw.declaredSize);
    domain.actualSize = raw.actualSize === null ? null : Number(raw.actualSize);
    domain.status = raw.status as MediaStatus;
    domain.moderationStatus = raw.moderationStatus;
    domain.createdAt = raw.createdAt;
    domain.updatedAt = raw.updatedAt;
    return domain;
  }

  static toPersistence(domain: MediaObject): MediaObjectEntity {
    const entity = new MediaObjectEntity();
    if (domain.id) {
      entity.id = domain.id;
    }
    entity.userId = domain.userId;
    entity.purpose = domain.purpose;
    entity.storageKey = domain.storageKey;
    entity.contentType = domain.contentType;
    entity.declaredSize = domain.declaredSize;
    entity.actualSize = domain.actualSize ?? null;
    entity.status = domain.status;
    entity.moderationStatus = domain.moderationStatus;
    entity.createdAt = domain.createdAt;
    entity.updatedAt = domain.updatedAt;
    return entity;
  }
}
