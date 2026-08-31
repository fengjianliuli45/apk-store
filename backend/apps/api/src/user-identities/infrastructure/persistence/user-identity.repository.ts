import { NullableType } from '../../../utils/types/nullable.type';
import { UserIdentity } from '../../domain/user-identity';

export abstract class UserIdentityRepository {
  abstract create(
    data: Pick<UserIdentity, 'provider' | 'providerUid' | 'userId'>,
  ): Promise<UserIdentity>;

  abstract findByProviderAndUid(
    provider: string,
    providerUid: string,
  ): Promise<NullableType<UserIdentity>>;

  abstract findByUserId(userId: number): Promise<UserIdentity[]>;

  abstract remove(id: UserIdentity['id']): Promise<void>;
}
