import { DeepPartial } from '../../../utils/types/deep-partial.type';
import { NullableType } from '../../../utils/types/nullable.type';
import { MediaObject } from '../../domain/media-object';

export abstract class MediaObjectRepository {
  abstract create(
    data: Omit<MediaObject, 'id' | 'createdAt' | 'updatedAt'>,
  ): Promise<MediaObject>;

  abstract findById(id: string): Promise<NullableType<MediaObject>>;

  abstract update(
    id: string,
    payload: DeepPartial<MediaObject>,
  ): Promise<MediaObject | null>;
}
