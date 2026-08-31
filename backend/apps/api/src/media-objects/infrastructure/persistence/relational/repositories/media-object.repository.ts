import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { MediaObjectEntity } from '../entities/media-object.entity';
import { NullableType } from '../../../../../utils/types/nullable.type';
import { DeepPartial } from '../../../../../utils/types/deep-partial.type';
import { MediaObject } from '../../../../domain/media-object';
import { MediaObjectRepository } from '../../media-object.repository';
import { MediaObjectMapper } from '../mappers/media-object.mapper';

@Injectable()
export class MediaObjectRelationalRepository implements MediaObjectRepository {
  constructor(
    @InjectRepository(MediaObjectEntity)
    private readonly repo: Repository<MediaObjectEntity>,
  ) {}

  async create(
    data: Omit<MediaObject, 'id' | 'createdAt' | 'updatedAt'>,
  ): Promise<MediaObject> {
    const entity = this.repo.create(
      MediaObjectMapper.toPersistence(data as MediaObject),
    );
    const saved = await this.repo.save(entity);
    return MediaObjectMapper.toDomain(saved);
  }

  async findById(id: string): Promise<NullableType<MediaObject>> {
    const entity = await this.repo.findOne({ where: { id } });
    return entity ? MediaObjectMapper.toDomain(entity) : null;
  }

  async update(
    id: string,
    payload: DeepPartial<MediaObject>,
  ): Promise<MediaObject | null> {
    const entity = await this.repo.findOne({ where: { id } });
    if (!entity) {
      return null;
    }
    const updated = await this.repo.save(
      this.repo.create(
        MediaObjectMapper.toPersistence({
          ...MediaObjectMapper.toDomain(entity),
          ...payload,
        } as MediaObject),
      ),
    );
    return MediaObjectMapper.toDomain(updated);
  }
}
