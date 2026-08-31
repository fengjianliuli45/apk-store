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
import { UserEntity } from '../../../../../users/infrastructure/persistence/relational/entities/user.entity';
import { newId } from '../../../../../common/id/uuid';

@Entity({ name: 'device_token' })
@Index('uq_device_token_user_token', ['userId', 'token'], { unique: true })
export class DeviceTokenEntity extends EntityRelationalHelper {
  @PrimaryColumn({ type: 'uuid' })
  id: string;

  @BeforeInsert()
  assignId() {
    if (!this.id) {
      this.id = newId();
    }
  }

  @Index()
  @Column({ type: Number })
  userId: number;

  @ManyToOne(() => UserEntity, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'userId' })
  user?: UserEntity;

  @Column({ type: String })
  platform: string;

  @Column({ type: String })
  token: string;

  @Column({ type: String, nullable: true })
  vendorChannel: string | null;

  @Column({ type: 'timestamp' })
  lastSeenAt: Date;

  @CreateDateColumn()
  createdAt: Date;
}
