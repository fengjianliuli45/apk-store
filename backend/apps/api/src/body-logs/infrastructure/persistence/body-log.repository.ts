import { NullableType } from '../../../utils/types/nullable.type';
import { CursorPage } from '../../../common/pagination/cursor';
import { BodyLog } from '../../domain/body-log';

export abstract class BodyLogRepository {
  /** 按 (userId, measuredOn) upsert：同一天再传 = 更新。 */
  abstract upsert(
    data: Omit<BodyLog, 'id' | 'createdAt' | 'updatedAt'>,
  ): Promise<BodyLog>;

  abstract findById(id: string): Promise<NullableType<BodyLog>>;

  abstract remove(id: string): Promise<void>;

  abstract list(
    userId: number,
    opts: {
      limit: number;
      cursor?: string | null;
      from?: string;
      to?: string;
    },
  ): Promise<CursorPage<BodyLog>>;
}
