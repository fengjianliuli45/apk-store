import { NotificationPreference } from '../../../../domain/notification-preference';
import { NotificationPreferenceEntity } from '../entities/notification-preference.entity';

export class NotificationPreferenceMapper {
  static toDomain(raw: NotificationPreferenceEntity): NotificationPreference {
    const d = new NotificationPreference();
    d.id = raw.id;
    d.userId = raw.userId;
    d.pushEnabled = raw.pushEnabled;
    d.categories = raw.categories ?? {};
    d.quietHoursStart = raw.quietHoursStart;
    d.quietHoursEnd = raw.quietHoursEnd;
    d.updatedAt = raw.updatedAt;
    return d;
  }

  static toPersistence(
    d: NotificationPreference,
  ): NotificationPreferenceEntity {
    const e = new NotificationPreferenceEntity();
    if (d.id) {
      e.id = d.id;
    }
    e.userId = d.userId;
    e.pushEnabled = d.pushEnabled;
    e.categories = d.categories ?? {};
    e.quietHoursStart = d.quietHoursStart ?? null;
    e.quietHoursEnd = d.quietHoursEnd ?? null;
    e.updatedAt = d.updatedAt;
    return e;
  }
}
