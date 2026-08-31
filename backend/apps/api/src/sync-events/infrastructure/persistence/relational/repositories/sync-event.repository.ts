import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { EntityManager, Repository } from 'typeorm';
import { SyncEventEntity } from '../entities/sync-event.entity';
import { NullableType } from '../../../../../utils/types/nullable.type';
import { SyncEvent } from '../../../../domain/sync-event';
import { SyncEventRepository } from '../../sync-event.repository';
import { SyncEventMapper } from '../mappers/sync-event.mapper';

@Injectable()
export class SyncEventRelationalRepository implements SyncEventRepository {
  constructor(
    @InjectRepository(SyncEventEntity)
    private readonly repo: Repository<SyncEventEntity>,
  ) {}

  async append(
    data: Omit<SyncEvent, 'id' | 'serverSeq' | 'createdAt'>,
  ): Promise<{ event: SyncEvent; deduped: boolean }> {
    // 单条事件的 seq 分配 + 幂等：小事务里 MAX+1，唯一约束兜底并发。
    for (let attempt = 0; attempt < 3; attempt++) {
      try {
        return await this.repo.manager.transaction(async (tx) => {
          if (data.clientEventId) {
            const existing = await tx.getRepository(SyncEventEntity).findOne({
              where: {
                userId: data.userId,
                clientEventId: data.clientEventId,
              },
            });
            if (existing) {
              return {
                event: SyncEventMapper.toDomain(existing),
                deduped: true,
              };
            }
          }

          const seq = (await this.maxSeqIn(tx, data.userId)) + 1;
          const entity = tx.getRepository(SyncEventEntity).create({
            userId: data.userId,
            serverSeq: seq,
            entityType: data.entityType,
            entityId: data.entityId ?? null,
            op: data.op,
            payload: data.payload,
            clientEventId: data.clientEventId ?? null,
            occurredAt: data.occurredAt,
          });
          const saved = await tx.getRepository(SyncEventEntity).save(entity);
          return { event: SyncEventMapper.toDomain(saved), deduped: false };
        });
      } catch (error) {
        const message = (error as { message?: string }).message ?? '';
        const isUnique =
          message.includes('uq_sync_event_user_seq') ||
          message.includes('uq_sync_event_user_client');
        if (!isUnique || attempt === 2) {
          throw error;
        }
        // 并发撞 seq 或 clientEventId：重试（下一轮会命中 dedup 或拿到新 seq）
      }
    }
    throw new Error('sync-event append: exhausted retries');
  }

  async findByUserAndClientEventId(
    userId: number,
    clientEventId: string,
  ): Promise<NullableType<SyncEvent>> {
    const entity = await this.repo.findOne({
      where: { userId, clientEventId },
    });
    return entity ? SyncEventMapper.toDomain(entity) : null;
  }

  async listSince(
    userId: number,
    afterSeq: number,
    limit: number,
  ): Promise<SyncEvent[]> {
    const entities = await this.repo
      .createQueryBuilder('e')
      .where('e.userId = :userId', { userId })
      .andWhere('e.serverSeq > :afterSeq', { afterSeq })
      .orderBy('e.serverSeq', 'ASC')
      .take(limit)
      .getMany();
    return entities.map((e) => SyncEventMapper.toDomain(e));
  }

  async maxSeq(userId: number): Promise<number> {
    return this.maxSeqIn(this.repo.manager, userId);
  }

  private async maxSeqIn(
    manager: EntityManager,
    userId: number,
  ): Promise<number> {
    const row = await manager
      .getRepository(SyncEventEntity)
      .createQueryBuilder('e')
      .select('MAX(e.serverSeq)', 'max')
      .where('e.userId = :userId', { userId })
      .getRawOne<{ max: string | null }>();
    return row?.max ? Number(row.max) : 0;
  }
}
