import {
  BeforeInsert,
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryColumn,
} from 'typeorm';
import { EntityRelationalHelper } from '../../../../../utils/relational-entity-helper';
import { TrainingPlanEntity } from '../../../../../training-plans/infrastructure/persistence/relational/entities/training-plan.entity';
import { newId } from '../../../../../common/id/uuid';

@Entity({ name: 'plan_version' })
@Index('uq_plan_version_plan_number', ['planId', 'versionNumber'], {
  unique: true,
})
export class PlanVersionEntity extends EntityRelationalHelper {
  @PrimaryColumn({ type: 'uuid' })
  id: string;

  @BeforeInsert()
  assignId() {
    if (!this.id) {
      this.id = newId();
    }
  }

  @Index()
  @Column({ type: 'uuid' })
  planId: string;

  @ManyToOne(() => TrainingPlanEntity, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'planId' })
  plan?: TrainingPlanEntity;

  @Column({ type: Number })
  versionNumber: number;

  @Column({ type: String })
  plannerVersion: string;

  @Column({ type: String })
  generatedBy: string;

  @Column({ type: 'jsonb' })
  inputSnapshot: Record<string, unknown>;

  @Column({ type: 'jsonb' })
  planJson: Record<string, unknown>;

  @Column({ type: String, nullable: true })
  changeReason: string | null;

  @CreateDateColumn()
  createdAt: Date;
}
