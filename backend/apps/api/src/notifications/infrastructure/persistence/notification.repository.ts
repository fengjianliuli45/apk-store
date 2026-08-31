import { CursorPage } from '../../../common/pagination/cursor';
import { Notification } from '../../domain/notification';

export abstract class NotificationRepository {
  abstract create(
    data: Omit<Notification, 'id' | 'createdAt'>,
  ): Promise<Notification>;

  abstract listByUser(
    userId: number,
    opts: { limit: number; cursor?: string | null; unreadOnly?: boolean },
  ): Promise<CursorPage<Notification>>;

  abstract unreadCount(userId: number): Promise<number>;

  /** ids 为空 = 全部标记已读。返回受影响条数。 */
  abstract markRead(userId: number, ids: string[]): Promise<number>;
}
