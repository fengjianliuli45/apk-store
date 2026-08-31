import { Injectable, Logger } from '@nestjs/common';
import { SyncEventRepository } from './infrastructure/persistence/sync-event.repository';
import { SyncEvent, SyncOp } from './domain/sync-event';

export type EmitInput = {
  userId: number;
  entityType: string;
  entityId?: string | null;
  op: SyncOp;
  payload: Record<string, unknown>;
  clientEventId?: string | null;
  occurredAt?: Date;
};

/**
 * 领域写操作成功后调用，把变更登记进 sync_event 变更流，供其它设备拉取。
 * v1：best-effort —— 登记失败不回滚业务写（变更流可从领域表重建）。见 packages/contracts/sync.md。
 */
@Injectable()
export class SyncEmitterService {
  private readonly logger = new Logger('SyncEmitter');

  constructor(private readonly repo: SyncEventRepository) {}

  async emit(
    input: EmitInput,
  ): Promise<{ event: SyncEvent; deduped: boolean } | null> {
    try {
      return await this.repo.append({
        userId: input.userId,
        entityType: input.entityType,
        entityId: input.entityId ?? null,
        op: input.op,
        payload: input.payload,
        clientEventId: input.clientEventId ?? null,
        occurredAt: input.occurredAt ?? new Date(),
      });
    } catch (error) {
      this.logger.error(
        `emit failed (user=${input.userId} ${input.entityType}/${input.op})`,
        error as Error,
      );
      return null;
    }
  }

  cursor(userId: number): Promise<number> {
    return this.repo.maxSeq(userId);
  }
}
