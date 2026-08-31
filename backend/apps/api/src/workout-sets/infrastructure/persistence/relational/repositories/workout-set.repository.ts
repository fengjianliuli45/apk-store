import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { WorkoutSetEntity } from '../entities/workout-set.entity';
import { NullableType } from '../../../../../utils/types/nullable.type';
import { DeepPartial } from '../../../../../utils/types/deep-partial.type';
import { WorkoutSet } from '../../../../domain/workout-set';
import { WorkoutSetRepository } from '../../workout-set.repository';
import { WorkoutSetMapper } from '../mappers/workout-set.mapper';

@Injectable()
export class WorkoutSetRelationalRepository implements WorkoutSetRepository {
  constructor(
    @InjectRepository(WorkoutSetEntity)
    private readonly repo: Repository<WorkoutSetEntity>,
  ) {}

  async createMany(
    data: Omit<WorkoutSet, 'id' | 'createdAt'>[],
  ): Promise<WorkoutSet[]> {
    const entities = data.map((d) =>
      this.repo.create(WorkoutSetMapper.toPersistence(d as WorkoutSet)),
    );
    const saved = await this.repo.save(entities);
    return saved.map((e) => WorkoutSetMapper.toDomain(e));
  }

  async findBySessionId(sessionId: string): Promise<WorkoutSet[]> {
    const entities = await this.repo.find({
      where: { sessionId },
      order: { setIndex: 'ASC', createdAt: 'ASC' },
    });
    return entities.map((e) => WorkoutSetMapper.toDomain(e));
  }

  async findById(id: string): Promise<NullableType<WorkoutSet>> {
    const entity = await this.repo.findOne({ where: { id } });
    return entity ? WorkoutSetMapper.toDomain(entity) : null;
  }

  async update(
    id: string,
    payload: DeepPartial<WorkoutSet>,
  ): Promise<WorkoutSet | null> {
    const entity = await this.repo.findOne({ where: { id } });
    if (!entity) {
      return null;
    }
    const updated = await this.repo.save(
      this.repo.create(
        WorkoutSetMapper.toPersistence({
          ...WorkoutSetMapper.toDomain(entity),
          ...payload,
        } as WorkoutSet),
      ),
    );
    return WorkoutSetMapper.toDomain(updated);
  }

  async remove(id: string): Promise<void> {
    await this.repo.delete(id);
  }
}
