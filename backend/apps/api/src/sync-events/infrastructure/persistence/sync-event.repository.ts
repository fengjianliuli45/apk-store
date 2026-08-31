import { NullableType } from '../../../utils/types/nullable.type';
import { SyncEvent } from '../../domain/sync-event';

export abstract class SyncEventRepository {
  /** 幂等追加一条事件；serverSeq 在事务里取 MAX+1。返回记录（含既有的，若 clientEventId 命中）。 */
  abstract append(
    data: Omit<SyncEvent, 'id' | 'serverSeq' | 'createdAt'>,
  ): Promise<{ event: SyncEvent; deduped: boolean }>;

  abstract findByUserAndClientEventId(
    userId: number,
    clientEventId: string,
  ): Promise<NullableType<SyncEvent>>;

  abstract listSince(
    userId: number,
    afterSeq: number,
    limit: number,
  ): Promise<SyncEvent[]>;

  abstract maxSeq(userId: number): Promise<number>;
}
