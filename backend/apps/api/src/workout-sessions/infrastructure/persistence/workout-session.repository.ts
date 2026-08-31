import { DeepPartial } from '../../../utils/types/deep-partial.type';
import { NullableType } from '../../../utils/types/nullable.type';
import { CursorPage } from '../../../common/pagination/cursor';
import { WorkoutSession } from '../../domain/workout-session';

export abstract class WorkoutSessionRepository {
  abstract create(
    data: Omit<WorkoutSession, 'id' | 'createdAt' | 'updatedAt'>,
  ): Promise<WorkoutSession>;

  abstract findById(id: string): Promise<NullableType<WorkoutSession>>;

  abstract listByUser(
    userId: number,
    limit: number,
    cursor?: string | null,
  ): Promise<CursorPage<WorkoutSession>>;

  abstract update(
    id: string,
    payload: DeepPartial<WorkoutSession>,
  ): Promise<WorkoutSession | null>;
}
