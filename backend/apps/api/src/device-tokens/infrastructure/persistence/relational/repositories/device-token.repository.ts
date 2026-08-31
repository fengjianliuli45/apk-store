import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { DeviceTokenEntity } from '../entities/device-token.entity';
import { DeviceToken } from '../../../../domain/device-token';
import { DeviceTokenRepository } from '../../device-token.repository';
import { DeviceTokenMapper } from '../mappers/device-token.mapper';

@Injectable()
export class DeviceTokenRelationalRepository implements DeviceTokenRepository {
  constructor(
    @InjectRepository(DeviceTokenEntity)
    private readonly repo: Repository<DeviceTokenEntity>,
  ) {}

  async upsert(
    data: Omit<DeviceToken, 'id' | 'createdAt'>,
  ): Promise<DeviceToken> {
    const existing = await this.repo.findOne({
      where: { userId: data.userId, token: data.token },
    });
    if (existing) {
      existing.platform = data.platform;
      existing.vendorChannel = data.vendorChannel ?? null;
      existing.lastSeenAt = data.lastSeenAt;
      const saved = await this.repo.save(existing);
      return DeviceTokenMapper.toDomain(saved);
    }
    const entity = this.repo.create(
      DeviceTokenMapper.toPersistence(data as DeviceToken),
    );
    const saved = await this.repo.save(entity);
    return DeviceTokenMapper.toDomain(saved);
  }

  async listByUser(userId: number): Promise<DeviceToken[]> {
    const rows = await this.repo.find({ where: { userId } });
    return rows.map((r) => DeviceTokenMapper.toDomain(r));
  }

  async removeByUserAndToken(userId: number, token: string): Promise<void> {
    await this.repo.delete({ userId, token });
  }
}
