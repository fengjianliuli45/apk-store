import { NotificationsService } from './notifications.service';
import { Notification } from './domain/notification';
import { NotificationRepository } from './infrastructure/persistence/notification.repository';
import { CursorPage } from '../common/pagination/cursor';
import { NotificationPreferencesService } from '../notification-preferences/notification-preferences.service';
import { NotificationPreference } from '../notification-preferences/domain/notification-preference';
import { NotificationPreferenceRepository } from '../notification-preferences/infrastructure/persistence/notification-preference.repository';
import { DeviceTokensService } from '../device-tokens/device-tokens.service';
import { DeviceToken } from '../device-tokens/domain/device-token';
import { DeviceTokenRepository } from '../device-tokens/infrastructure/persistence/device-token.repository';
import { ConsolePushService, PushService } from './push/push.service';

class MemNotifRepo implements NotificationRepository {
  rows: Notification[] = [];
  create(d: Omit<Notification, 'id' | 'createdAt'>) {
    const row: Notification = {
      ...(d as Notification),
      id: `n-${this.rows.length + 1}`,
      createdAt: new Date(),
    };
    this.rows.push(row);
    return Promise.resolve(row);
  }
  listByUser(): Promise<CursorPage<Notification>> {
    return Promise.resolve({ data: this.rows, nextCursor: null });
  }
  unreadCount(userId: number) {
    return Promise.resolve(
      this.rows.filter((r) => r.userId === userId && !r.readAt).length,
    );
  }
  markRead(userId: number, ids: string[]) {
    let n = 0;
    for (const r of this.rows) {
      if (r.userId !== userId || r.readAt) continue;
      if (ids.length === 0 || ids.includes(r.id)) {
        r.readAt = new Date();
        n++;
      }
    }
    return Promise.resolve(n);
  }
}

class MemPrefRepo implements NotificationPreferenceRepository {
  rows: NotificationPreference[] = [];
  create(d: Omit<NotificationPreference, 'id' | 'updatedAt'>) {
    const row: NotificationPreference = {
      ...(d as NotificationPreference),
      id: `pref-${this.rows.length + 1}`,
      updatedAt: new Date(),
    };
    this.rows.push(row);
    return Promise.resolve(row);
  }
  findByUserId(userId: number) {
    return Promise.resolve(this.rows.find((r) => r.userId === userId) ?? null);
  }
  update(id: string, p: Partial<NotificationPreference>) {
    const row = this.rows.find((r) => r.id === id);
    if (!row) return Promise.resolve(null);
    Object.assign(row, p);
    return Promise.resolve(row);
  }
}

class MemDeviceRepo implements DeviceTokenRepository {
  rows: DeviceToken[] = [];
  upsert(d: Omit<DeviceToken, 'id' | 'createdAt'>) {
    const existing = this.rows.find(
      (r) => r.userId === d.userId && r.token === d.token,
    );
    if (existing) {
      Object.assign(existing, d);
      return Promise.resolve(existing);
    }
    const row: DeviceToken = {
      ...(d as DeviceToken),
      id: `d-${this.rows.length + 1}`,
      createdAt: new Date(),
    };
    this.rows.push(row);
    return Promise.resolve(row);
  }
  listByUser(userId: number) {
    return Promise.resolve(this.rows.filter((r) => r.userId === userId));
  }
  removeByUserAndToken(userId: number, token: string) {
    this.rows = this.rows.filter(
      (r) => !(r.userId === userId && r.token === token),
    );
    return Promise.resolve();
  }
}

describe('NotificationsService', () => {
  let notifRepo: MemNotifRepo;
  let prefRepo: MemPrefRepo;
  let deviceRepo: MemDeviceRepo;
  let push: PushService;
  let sendSpy: jest.SpyInstance;
  let service: NotificationsService;
  let devices: DeviceTokensService;

  beforeEach(() => {
    notifRepo = new MemNotifRepo();
    prefRepo = new MemPrefRepo();
    deviceRepo = new MemDeviceRepo();
    push = new ConsolePushService();
    sendSpy = jest.spyOn(push, 'send');
    devices = new DeviceTokensService(deviceRepo);
    service = new NotificationsService(
      notifRepo,
      new NotificationPreferencesService(prefRepo),
      devices,
      push,
    );
  });

  const input = {
    type: 'social_like',
    category: 'social',
    title: 'x 点赞了你',
    body: '',
  };

  it('should store a notification and push to every device', async () => {
    await devices.register(1, { platform: 'ios', token: 'tok-a' });
    await devices.register(1, { platform: 'android_fcm', token: 'tok-b' });
    await service.notify(1, input);
    expect(notifRepo.rows).toHaveLength(1);
    expect(sendSpy).toHaveBeenCalledTimes(2);
  });

  it('should store but not push when pushEnabled is false', async () => {
    await devices.register(1, { platform: 'ios', token: 'tok-a' });
    await new NotificationPreferencesService(prefRepo).update(1, {
      pushEnabled: false,
    });
    await service.notify(1, input);
    expect(notifRepo.rows).toHaveLength(1);
    expect(sendSpy).not.toHaveBeenCalled();
  });

  it('should not push a category the user turned off', async () => {
    await devices.register(1, { platform: 'ios', token: 'tok-a' });
    await new NotificationPreferencesService(prefRepo).update(1, {
      categories: { social: false },
    });
    await service.notify(1, input);
    expect(sendSpy).not.toHaveBeenCalled();
  });

  it('should suppress push during quiet hours', async () => {
    await devices.register(1, { platform: 'ios', token: 'tok-a' });
    const hour = new Date().getUTCHours();
    await new NotificationPreferencesService(prefRepo).update(1, {
      quietHoursStart: hour,
      quietHoursEnd: (hour + 1) % 24,
    });
    await service.notify(1, input);
    expect(sendSpy).not.toHaveBeenCalled();
    expect(notifRepo.rows).toHaveLength(1);
  });

  it('should count and clear unread', async () => {
    await service.notify(1, input);
    await service.notify(1, input);
    expect(await service.unreadCount(1)).toBe(2);
    const { updated } = { updated: await service.markRead(1, { all: true }) };
    expect(updated).toBe(2);
    expect(await service.unreadCount(1)).toBe(0);
  });

  it('should upsert a device token instead of duplicating', async () => {
    await devices.register(1, { platform: 'android_fcm', token: 'same' });
    await devices.register(1, {
      platform: 'android_vendor',
      token: 'same',
      vendorChannel: 'xiaomi',
    });
    const list = await devices.list(1);
    expect(list).toHaveLength(1);
    expect(list[0].vendorChannel).toBe('xiaomi');
  });

  it('should not let a push failure break notify', async () => {
    sendSpy.mockRejectedValueOnce(new Error('boom'));
    await devices.register(1, { platform: 'ios', token: 'tok-a' });
    await expect(service.notify(1, input)).resolves.toMatchObject({
      type: 'social_like',
    });
  });
});
