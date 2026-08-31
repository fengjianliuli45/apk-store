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

@Entity({ name: 'report' })
@Index('IDX_report_status_created', ['status', 'createdAt'])
export class ReportEntity extends EntityRelationalHelper {
  @PrimaryColumn({ type: 'uuid' })
  id: string;

  @BeforeInsert()
  assignId() {
    if (!this.id) {
      this.id = newId();
    }
  }

  @Column({ type: Number })
  reporterId: number;

  @Column({ type: String })
  targetType: string;

  @Column({ type: String })
  targetId: string;

  @Column({ type: String })
  reason: string;

  @Column({ type: 'text', nullable: true })
  detail: string | null;

  @Column({ type: String, default: 'open' })
  status: string;

  @CreateDateColumn()
  createdAt: Date;
}
