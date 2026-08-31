import { Injectable, Logger } from '@nestjs/common';
import { NotificationRepository } from './infrastructure/persistence/notification.repository';
import { Notification } from './domain/notification';
import { CursorPage } from '../common/pagination/cursor';
import { NotificationPreferencesService } from '../notification-preferences/notification-preferences.service';
import { DeviceTokensService } from '../device-tokens/device-tokens.service';
import { PushService } from './push/push.service';
import { MarkReadDto } from './dto/mark-read.dto';

export type NotifyInput = {
  type: string;
  category: string;
  title: string;
  body: string;
  data?: Record<string, unknown>;
};

/**
 * 其它模块通过 `notify()` 发通知：落一条站内通知 + 按偏好 / 免打扰决定是否推送。
 * 推送 best-effort（失败只记日志，不影响业务）。
 */
@Injectable()
export class NotificationsService {
  private readonly logger = new Logger('NotificationsService');

  constructor(
    private readonly repo: NotificationRepository,
    private readonly prefs: NotificationPreferencesService,
    private readonly devices: DeviceTokensService,
    private readonly push: PushService,
  ) {}

  list(
    userId: number,
    opts: { limit: number; cursor?: string | null; unreadOnly?: boolean },
  ): Promise<CursorPage<Notification>> {
    return this.repo.listByUser(userId, opts);
  }

  unreadCount(userId: number): Promise<number> {
    return this.repo.unreadCount(userId);
  }

  markRead(userId: number, dto: MarkReadDto): Promise<number> {
    return this.repo.markRead(userId, dto.all ? [] : (dto.ids ?? []));
  }

  async notify(userId: number, input: NotifyInput): Promise<Notification> {
    const notification = await this.repo.create({
      userId,
      type: input.type,
      title: input.title,
      body: input.body,
      data: input.data ?? {},
      readAt: null,
    });

    await this.maybePush(userId, input, notification);
    return notification;
  }

  private async maybePush(
    userId: number,
    input: NotifyInput,
    notification: Notification,
  ): Promise<void> {
    try {
      const pref = await this.prefs.getOrDefault(userId);
      if (!pref.pushEnabled) {
        return;
      }
      if (pref.categories[input.category] === false) {
        return;
      }
      if (this.inQuietHours(pref.quietHoursStart, pref.quietHoursEnd)) {
        return;
      }

      const tokens = await this.devices.list(userId);
      const message = {
        title: input.title,
        body: input.body,
        data: { ...(input.data ?? {}), notificationId: notification.id },
      };

      await Promise.all(
        tokens.map(async (t) => {
          const res = await this.push.send(
            {
              platform: t.platform,
              token: t.token,
              vendorChannel: t.vendorChannel,
            },
            message,
          );
          if (!res.ok) {
            this.logger.warn(
              `push failed user=${userId} token=${t.id}: ${res.error}`,
            );
          }
        }),
      );
    } catch (error) {
      this.logger.error(`maybePush failed user=${userId}`, error as Error);
    }
  }

  private inQuietHours(start: number | null, end: number | null): boolean {
    if (start === null || end === null) {
      return false;
    }
    const hour = new Date().getUTCHours();
    // 跨零点：start=22 end=8 → 22,23,0..7 静默
    return start <= end
      ? hour >= start && hour < end
      : hour >= start || hour < end;
  }
}
