import { Notification } from '../../../../domain/notification';
import { NotificationEntity } from '../entities/notification.entity';

export class NotificationMapper {
  static toDomain(raw: NotificationEntity): Notification {
    const d = new Notification();
    d.id = raw.id;
    d.userId = raw.userId;
    d.type = raw.type;
    d.title = raw.title;
    d.body = raw.body;
    d.data = raw.data ?? {};
    d.readAt = raw.readAt;
    d.createdAt = raw.createdAt;
    return d;
  }

  static toPersistence(d: Notification): NotificationEntity {
    const e = new NotificationEntity();
    if (d.id) {
      e.id = d.id;
    }
    e.userId = d.userId;
    e.type = d.type;
    e.title = d.title;
    e.body = d.body;
    e.data = d.data ?? {};
    e.readAt = d.readAt ?? null;
    e.createdAt = d.createdAt;
    return e;
  }
}
