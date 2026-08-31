import { Injectable } from '@nestjs/common';
import { DeviceTokenRepository } from './infrastructure/persistence/device-token.repository';
import { DeviceToken, DevicePlatform } from './domain/device-token';
import { RegisterDeviceDto } from './dto/register-device.dto';

@Injectable()
export class DeviceTokensService {
  constructor(private readonly repo: DeviceTokenRepository) {}

  register(userId: number, dto: RegisterDeviceDto): Promise<DeviceToken> {
    return this.repo.upsert({
      userId,
      platform: dto.platform as DevicePlatform,
      token: dto.token,
      vendorChannel: dto.vendorChannel ?? null,
      lastSeenAt: new Date(),
    });
  }

  list(userId: number): Promise<DeviceToken[]> {
    return this.repo.listByUser(userId);
  }

  unregister(userId: number, token: string): Promise<void> {
    return this.repo.removeByUserAndToken(userId, token);
  }
}
