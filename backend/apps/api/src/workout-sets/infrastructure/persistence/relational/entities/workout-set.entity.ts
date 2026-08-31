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
import { WorkoutSessionEntity } from '../../../../../workout-sessions/infrastructure/persistence/relational/entities/workout-session.entity';
import { newId } from '../../../../../common/id/uuid';

@Entity({ name: 'workout_set' })
export class WorkoutSetEntity extends EntityRelationalHelper {
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
  sessionId: string;

  @ManyToOne(() => WorkoutSessionEntity, {
    onDelete: 'CASCADE',
    nullable: false,
  })
  @JoinColumn({ name: 'sessionId' })
  session?: WorkoutSessionEntity;

  @Column({ type: String })
  exerciseKey: string;

  @Column({ type: String })
  exerciseName: string;

  @Column({ type: Number })
  setIndex: number;

  @Column({ type: Number, nullable: true })
  reps: number | null;

  @Column({ type: 'real', nullable: true })
  weightKg: number | null;

  @Column({ type: 'real', nullable: true })
  rir: number | null;

  @Column({ type: Boolean, default: false })
  isWarmup: boolean;

  @Column({ type: 'timestamp', nullable: true })
  completedAt: Date | null;

  @CreateDateColumn()
  createdAt: Date;
}
