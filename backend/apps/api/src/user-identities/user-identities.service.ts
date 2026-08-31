import { Injectable } from '@nestjs/common';
import { NullableType } from '../utils/types/nullable.type';
import { UserIdentityRepository } from './infrastructure/persistence/user-identity.repository';
import { UserIdentity } from './domain/user-identity';

@Injectable()
export class UserIdentitiesService {
  constructor(
    private readonly userIdentityRepository: UserIdentityRepository,
  ) {}

  findByProviderAndUid(
    provider: string,
    providerUid: string,
  ): Promise<NullableType<UserIdentity>> {
    return this.userIdentityRepository.findByProviderAndUid(
      provider,
      providerUid,
    );
  }

  findByUserId(userId: number): Promise<UserIdentity[]> {
    return this.userIdentityRepository.findByUserId(userId);
  }

  link(data: {
    provider: string;
    providerUid: string;
    userId: number;
  }): Promise<UserIdentity> {
    return this.userIdentityRepository.create(data);
  }

  remove(id: UserIdentity['id']): Promise<void> {
    return this.userIdentityRepository.remove(id);
  }
}
