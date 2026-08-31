import { DeepPartial } from '../../../utils/types/deep-partial.type';
import { NullableType } from '../../../utils/types/nullable.type';
import { Profile } from '../../domain/profile';

export abstract class ProfileRepository {
  abstract create(
    data: Omit<Profile, 'id' | 'createdAt' | 'updatedAt'>,
  ): Promise<Profile>;

  abstract findByUserId(userId: number): Promise<NullableType<Profile>>;

  abstract update(
    id: Profile['id'],
    payload: DeepPartial<Profile>,
  ): Promise<Profile | null>;

  abstract remove(id: Profile['id']): Promise<void>;
}
