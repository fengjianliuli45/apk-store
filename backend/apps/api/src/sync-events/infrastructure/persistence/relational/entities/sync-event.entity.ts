import {
  BeforeInsert,
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryColumn,
} from 'typeorm';
import { EntityRelationalHelper } from '../../../../../utils/relational-entity-helper';
import { newId } from '../../../../../common/id/uuid';

@Entity({ name: 'sync_event' })
@Index('uq_sync_event_user_seq', ['userId', 'serverSeq'], { unique: true })
@Index('uq_sync_event_user_client', ['userId', 'clientEventId'], {
  unique: true,
  where: '"clientEventId" IS NOT NULL',
})
export class SyncEventEntity extends EntityRelationalHelper {
  @PrimaryColumn({ type: 'uuid' })
  id: string;

  @BeforeInsert()
  assignId() {
    if (!this.id) {
      this.id = newId();
    }
  }

  @Column({ type: Number })
  userId: number;

  @Column({ type: 'int' })
  serverSeq: number;

  @Column({ type: String })
  entityType: string;

  @Column({ type: String, nullable: true })
  entityId: string | null;

  @Column({ type: String })
  op: string;

  @Column({ type: 'jsonb' })
  payload: Record<string, unknown>;

  @Column({ type: String, nullable: true })
  clientEventId: string | null;

  @Column({ type: 'timestamp' })
  occurredAt: Date;

  @CreateDateColumn()
  createdAt: Date;
}
