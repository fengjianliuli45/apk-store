import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { UserIdentityEntity } from '../entities/user-identity.entity';
import { NullableType } from '../../../../../utils/types/nullable.type';
import { UserIdentity } from '../../../../domain/user-identity';
import { UserIdentityRepository } from '../../user-identity.repository';
import { UserIdentityMapper } from '../mappers/user-identity.mapper';

@Injectable()
export class UserIdentityRelationalRepository implements UserIdentityRepository {
  constructor(
    @InjectRepository(UserIdentityEntity)
    private readonly userIdentityRepository: Repository<UserIdentityEntity>,
  ) {}

  async create(
    data: Pick<UserIdentity, 'provider' | 'providerUid' | 'userId'>,
  ): Promise<UserIdentity> {
    const entity = this.userIdentityRepository.create({
      provider: data.provider,
      providerUid: data.providerUid,
      userId: data.userId,
    });
    const saved = await this.userIdentityRepository.save(entity);
    return UserIdentityMapper.toDomain(saved);
  }

  async findByProviderAndUid(
    provider: string,
    providerUid: string,
  ): Promise<NullableType<UserIdentity>> {
    const entity = await this.userIdentityRepository.findOne({
      where: { provider, providerUid },
    });
    return entity ? UserIdentityMapper.toDomain(entity) : null;
  }

  async findByUserId(userId: number): Promise<UserIdentity[]> {
    const entities = await this.userIdentityRepository.find({
      where: { userId },
    });
    return entities.map((entity) => UserIdentityMapper.toDomain(entity));
  }

  async remove(id: UserIdentity['id']): Promise<void> {
    await this.userIdentityRepository.delete(id);
  }
}
