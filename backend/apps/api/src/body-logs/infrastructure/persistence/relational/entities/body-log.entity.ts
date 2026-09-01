import {
  BeforeInsert,
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryColumn,
  UpdateDateColumn,
} from 'typeorm';
import { EntityRelationalHelper } from '../../../../../utils/relational-entity-helper';
import { UserEntity } from '../../../../../users/infrastructure/persistence/relational/entities/user.entity';
import { newId } from '../../../../../common/id/uuid';

@Entity({ name: 'body_log' })
@Index('uq_body_log_user_date', ['userId', 'measuredOn'], { unique: true })
export class BodyLogEntity extends EntityRelationalHelper {
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

  @ManyToOne(() => UserEntity, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'userId' })
  user?: UserEntity;

  @Column({ type: 'date' })
  measuredOn: string;

  @Column({ type: 'real', nullable: true })
  weightKg: number | null;

  @Column({ type: 'real', nullable: true })
  bodyFatPct: number | null;

  @Column({ type: 'real', nullable: true })
  waistCm: number | null;

  @Column({ type: 'real', nullable: true })
  armCm: number | null;

  @Column({ type: 'real', nullable: true })
  thighCm: number | null;

  @Column({ type: 'text', nullable: true })
  note: string | null;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
