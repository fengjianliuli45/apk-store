import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { NotificationPreferenceEntity } from '../entities/notification-preference.entity';
import { NullableType } from '../../../../../utils/types/nullable.type';
import { DeepPartial } from '../../../../../utils/types/deep-partial.type';
import { NotificationPreference } from '../../../../domain/notification-preference';
import { NotificationPreferenceRepository } from '../../notification-preference.repository';
import { NotificationPreferenceMapper } from '../mappers/notification-preference.mapper';

@Injectable()
export class NotificationPreferenceRelationalRepository implements NotificationPreferenceRepository {
  constructor(
    @InjectRepository(NotificationPreferenceEntity)
    private readonly repo: Repository<NotificationPreferenceEntity>,
  ) {}

  async create(
    data: Omit<NotificationPreference, 'id' | 'updatedAt'>,
  ): Promise<NotificationPreference> {
    const entity = this.repo.create(
      NotificationPreferenceMapper.toPersistence(
        data as NotificationPreference,
      ),
    );
    const saved = await this.repo.save(entity);
    return NotificationPreferenceMapper.toDomain(saved);
  }

  async findByUserId(
    userId: number,
  ): Promise<NullableType<NotificationPreference>> {
    const entity = await this.repo.findOne({ where: { userId } });
    return entity ? NotificationPreferenceMapper.toDomain(entity) : null;
  }

  async update(
    id: string,
    payload: DeepPartial<NotificationPreference>,
  ): Promise<NotificationPreference | null> {
    const entity = await this.repo.findOne({ where: { id } });
    if (!entity) {
      return null;
    }
    const updated = await this.repo.save(
      this.repo.create(
        NotificationPreferenceMapper.toPersistence({
          ...NotificationPreferenceMapper.toDomain(entity),
          ...payload,
        } as NotificationPreference),
      ),
    );
    return NotificationPreferenceMapper.toDomain(updated);
  }
}
