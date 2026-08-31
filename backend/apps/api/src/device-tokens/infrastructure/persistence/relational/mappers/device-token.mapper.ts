import { DevicePlatform, DeviceToken } from '../../../../domain/device-token';
import { DeviceTokenEntity } from '../entities/device-token.entity';

export class DeviceTokenMapper {
  static toDomain(raw: DeviceTokenEntity): DeviceToken {
    const d = new DeviceToken();
    d.id = raw.id;
    d.userId = raw.userId;
    d.platform = raw.platform as DevicePlatform;
    d.token = raw.token;
    d.vendorChannel = raw.vendorChannel;
    d.lastSeenAt = raw.lastSeenAt;
    d.createdAt = raw.createdAt;
    return d;
  }

  static toPersistence(d: DeviceToken): DeviceTokenEntity {
    const e = new DeviceTokenEntity();
    if (d.id) {
      e.id = d.id;
    }
    e.userId = d.userId;
    e.platform = d.platform;
    e.token = d.token;
    e.vendorChannel = d.vendorChannel ?? null;
    e.lastSeenAt = d.lastSeenAt;
    e.createdAt = d.createdAt;
    return e;
  }
}
