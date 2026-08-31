import { DeviceToken } from '../../domain/device-token';

export abstract class DeviceTokenRepository {
  /** 注册 / 刷新一台设备的 token（按 (userId, token) upsert）。 */
  abstract upsert(
    data: Omit<DeviceToken, 'id' | 'createdAt'>,
  ): Promise<DeviceToken>;

  abstract listByUser(userId: number): Promise<DeviceToken[]>;

  abstract removeByUserAndToken(userId: number, token: string): Promise<void>;
}
