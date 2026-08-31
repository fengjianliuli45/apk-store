import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { TrainingPlanEntity } from '../entities/training-plan.entity';
import { NullableType } from '../../../../../utils/types/nullable.type';
import { DeepPartial } from '../../../../../utils/types/deep-partial.type';
import { TrainingPlan } from '../../../../domain/training-plan';
import { TrainingPlanRepository } from '../../training-plan.repository';
import { TrainingPlanMapper } from '../mappers/training-plan.mapper';

@Injectable()
export class TrainingPlanRelationalRepository implements TrainingPlanRepository {
  constructor(
    @InjectRepository(TrainingPlanEntity)
    private readonly repo: Repository<TrainingPlanEntity>,
  ) {}

  async create(
    data: Omit<TrainingPlan, 'id' | 'createdAt' | 'updatedAt'>,
  ): Promise<TrainingPlan> {
    const entity = this.repo.create(
      TrainingPlanMapper.toPersistence(data as TrainingPlan),
    );
    const saved = await this.repo.save(entity);
    return TrainingPlanMapper.toDomain(saved);
  }

  async findById(id: string): Promise<NullableType<TrainingPlan>> {
    const entity = await this.repo.findOne({ where: { id } });
    return entity ? TrainingPlanMapper.toDomain(entity) : null;
  }

  async findActiveByUserId(
    userId: number,
  ): Promise<NullableType<TrainingPlan>> {
    const entity = await this.repo.findOne({
      where: { userId, status: 'active' },
    });
    return entity ? TrainingPlanMapper.toDomain(entity) : null;
  }

  async update(
    id: string,
    payload: DeepPartial<TrainingPlan>,
  ): Promise<TrainingPlan | null> {
    const entity = await this.repo.findOne({ where: { id } });
    if (!entity) {
      return null;
    }
    const updated = await this.repo.save(
      this.repo.create(
        TrainingPlanMapper.toPersistence({
          ...TrainingPlanMapper.toDomain(entity),
          ...payload,
        } as TrainingPlan),
      ),
    );
    return TrainingPlanMapper.toDomain(updated);
  }
}
