import {
  BeforeInsert,
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  OneToOne,
  PrimaryColumn,
  UpdateDateColumn,
} from 'typeorm';
import { EntityRelationalHelper } from '../../../../../utils/relational-entity-helper';
import { UserEntity } from '../../../../../users/infrastructure/persistence/relational/entities/user.entity';
import { newId } from '../../../../../common/id/uuid';

@Entity({
  name: 'profile',
})
export class ProfileEntity extends EntityRelationalHelper {
  @PrimaryColumn({ type: 'uuid' })
  id: string;

  @BeforeInsert()
  assignId() {
    if (!this.id) {
      this.id = newId();
    }
  }

  @Index({ unique: true })
  @Column({ type: Number })
  userId: number;

  @OneToOne(() => UserEntity, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'userId' })
  user?: UserEntity;

  @Column({ type: String, nullable: true })
  sex: string | null;

  @Column({ type: 'date', nullable: true })
  birthdate: string | null;

  @Column({ type: 'real', nullable: true })
  heightCm: number | null;

  @Column({ type: String, nullable: true })
  goal: string | null;

  @Column({ type: String, nullable: true })
  experienceLevel: string | null;

  @Column({ type: Number, nullable: true })
  minutesPerSession: number | null;

  @Column({ type: Number, nullable: true })
  mealsPerDay: number | null;

  @Column({ type: String, nullable: true })
  cookingAccess: string | null;

  @Column({ type: 'real', nullable: true })
  targetWeightKg: number | null;

  @Column({ type: 'text', nullable: true })
  injuriesText: string | null;

  @Column({ type: 'jsonb', default: () => "'[]'" })
  equipment: string[];

  @Column({ type: 'jsonb', default: () => "'[]'" })
  dietaryRestrictions: string[];

  @Column({ type: 'timestamp', nullable: true })
  bodyDataConsentAt: Date | null;

  @Column({ type: String, nullable: true })
  bodyDataConsentVersion: string | null;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
