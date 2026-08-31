import { DeepPartial } from '../../../utils/types/deep-partial.type';
import { NullableType } from '../../../utils/types/nullable.type';
import { TrainingPlan } from '../../domain/training-plan';

export abstract class TrainingPlanRepository {
  abstract create(
    data: Omit<TrainingPlan, 'id' | 'createdAt' | 'updatedAt'>,
  ): Promise<TrainingPlan>;

  abstract findById(
    id: TrainingPlan['id'],
  ): Promise<NullableType<TrainingPlan>>;

  abstract findActiveByUserId(
    userId: number,
  ): Promise<NullableType<TrainingPlan>>;

  abstract update(
    id: TrainingPlan['id'],
    payload: DeepPartial<TrainingPlan>,
  ): Promise<TrainingPlan | null>;
}
