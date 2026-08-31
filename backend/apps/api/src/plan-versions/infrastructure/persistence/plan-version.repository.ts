import { NullableType } from '../../../utils/types/nullable.type';
import { CursorPage } from '../../../common/pagination/cursor';
import { PlanVersion } from '../../domain/plan-version';

export abstract class PlanVersionRepository {
  abstract create(
    data: Omit<PlanVersion, 'id' | 'createdAt'>,
  ): Promise<PlanVersion>;

  abstract findById(id: PlanVersion['id']): Promise<NullableType<PlanVersion>>;

  abstract listByPlan(
    planId: string,
    limit: number,
    cursor?: string | null,
  ): Promise<CursorPage<PlanVersion>>;
}
