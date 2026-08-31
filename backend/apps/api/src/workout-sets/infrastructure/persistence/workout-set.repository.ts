import { DeepPartial } from '../../../utils/types/deep-partial.type';
import { NullableType } from '../../../utils/types/nullable.type';
import { WorkoutSet } from '../../domain/workout-set';

export abstract class WorkoutSetRepository {
  abstract createMany(
    data: Omit<WorkoutSet, 'id' | 'createdAt'>[],
  ): Promise<WorkoutSet[]>;

  abstract findBySessionId(sessionId: string): Promise<WorkoutSet[]>;

  abstract findById(id: string): Promise<NullableType<WorkoutSet>>;

  abstract update(
    id: string,
    payload: DeepPartial<WorkoutSet>,
  ): Promise<WorkoutSet | null>;

  abstract remove(id: string): Promise<void>;
}
