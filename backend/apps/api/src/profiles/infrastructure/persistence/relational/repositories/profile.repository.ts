import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ProfileEntity } from '../entities/profile.entity';
import { NullableType } from '../../../../../utils/types/nullable.type';
import { DeepPartial } from '../../../../../utils/types/deep-partial.type';
import { Profile } from '../../../../domain/profile';
import { ProfileRepository } from '../../profile.repository';
import { ProfileMapper } from '../mappers/profile.mapper';

@Injectable()
export class ProfileRelationalRepository implements ProfileRepository {
  constructor(
    @InjectRepository(ProfileEntity)
    private readonly profileRepository: Repository<ProfileEntity>,
  ) {}

  async create(
    data: Omit<Profile, 'id' | 'createdAt' | 'updatedAt'>,
  ): Promise<Profile> {
    const entity = this.profileRepository.create(
      ProfileMapper.toPersistence(data as Profile),
    );
    const saved = await this.profileRepository.save(entity);
    return ProfileMapper.toDomain(saved);
  }

  async findByUserId(userId: number): Promise<NullableType<Profile>> {
    const entity = await this.profileRepository.findOne({ where: { userId } });
    return entity ? ProfileMapper.toDomain(entity) : null;
  }

  async update(
    id: Profile['id'],
    payload: DeepPartial<Profile>,
  ): Promise<Profile | null> {
    const entity = await this.profileRepository.findOne({ where: { id } });
    if (!entity) {
      return null;
    }
    const updated = await this.profileRepository.save(
      this.profileRepository.create(
        ProfileMapper.toPersistence({
          ...ProfileMapper.toDomain(entity),
          ...payload,
        } as Profile),
      ),
    );
    return ProfileMapper.toDomain(updated);
  }

  async remove(id: Profile['id']): Promise<void> {
    await this.profileRepository.delete(id);
  }
}
