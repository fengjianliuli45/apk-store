import { UserIdentity } from '../../../../domain/user-identity';
import { UserIdentityEntity } from '../entities/user-identity.entity';

export class UserIdentityMapper {
  static toDomain(raw: UserIdentityEntity): UserIdentity {
    const domainEntity = new UserIdentity();
    domainEntity.id = raw.id;
    domainEntity.provider = raw.provider;
    domainEntity.providerUid = raw.providerUid;
    domainEntity.userId = raw.userId;
    domainEntity.createdAt = raw.createdAt;
    domainEntity.updatedAt = raw.updatedAt;
    return domainEntity;
  }

  static toPersistence(domainEntity: UserIdentity): UserIdentityEntity {
    const persistenceEntity = new UserIdentityEntity();
    if (domainEntity.id) {
      persistenceEntity.id = domainEntity.id;
    }
    persistenceEntity.provider = domainEntity.provider;
    persistenceEntity.providerUid = domainEntity.providerUid;
    persistenceEntity.userId = domainEntity.userId;
    persistenceEntity.createdAt = domainEntity.createdAt;
    persistenceEntity.updatedAt = domainEntity.updatedAt;
    return persistenceEntity;
  }
}
