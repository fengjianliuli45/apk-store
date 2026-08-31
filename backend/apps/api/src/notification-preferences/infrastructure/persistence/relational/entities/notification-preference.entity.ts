import {
  BeforeInsert,
  Column,
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

@Entity({ name: 'notification_preference' })
export class NotificationPreferenceEntity extends EntityRelationalHelper {
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

  @Column({ type: Boolean, default: true })
  pushEnabled: boolean;

  @Column({ type: 'jsonb', default: () => "'{}'" })
  categories: Record<string, boolean>;

  @Column({ type: 'smallint', nullable: true })
  quietHoursStart: number | null;

  @Column({ type: 'smallint', nullable: true })
  quietHoursEnd: number | null;

  @UpdateDateColumn()
  updatedAt: Date;
}
