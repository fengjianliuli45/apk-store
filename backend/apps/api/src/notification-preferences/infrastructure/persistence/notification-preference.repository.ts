import { DeepPartial } from '../../../utils/types/deep-partial.type';
import { NullableType } from '../../../utils/types/nullable.type';
import { NotificationPreference } from '../../domain/notification-preference';

export abstract class NotificationPreferenceRepository {
  abstract create(
    data: Omit<NotificationPreference, 'id' | 'updatedAt'>,
  ): Promise<NotificationPreference>;

  abstract findByUserId(
    userId: number,
  ): Promise<NullableType<NotificationPreference>>;

  abstract update(
    id: string,
    payload: DeepPartial<NotificationPreference>,
  ): Promise<NotificationPreference | null>;
}
