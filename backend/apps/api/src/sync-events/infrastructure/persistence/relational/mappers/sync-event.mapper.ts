import { SyncEvent, SyncOp } from '../../../../domain/sync-event';
import { SyncEventEntity } from '../entities/sync-event.entity';

export class SyncEventMapper {
  static toDomain(raw: SyncEventEntity): SyncEvent {
    const domain = new SyncEvent();
    domain.id = raw.id;
    domain.userId = raw.userId;
    domain.serverSeq = Number(raw.serverSeq);
    domain.entityType = raw.entityType;
    domain.entityId = raw.entityId;
    domain.op = raw.op as SyncOp;
    domain.payload = raw.payload;
    domain.clientEventId = raw.clientEventId;
    domain.occurredAt = raw.occurredAt;
    domain.createdAt = raw.createdAt;
    return domain;
  }

  static toPersistence(domain: SyncEvent): SyncEventEntity {
    const entity = new SyncEventEntity();
    if (domain.id) {
      entity.id = domain.id;
    }
    entity.userId = domain.userId;
    entity.serverSeq = domain.serverSeq;
    entity.entityType = domain.entityType;
    entity.entityId = domain.entityId ?? null;
    entity.op = domain.op;
    entity.payload = domain.payload;
    entity.clientEventId = domain.clientEventId ?? null;
    entity.occurredAt = domain.occurredAt;
    entity.createdAt = domain.createdAt;
    return entity;
  }
}
