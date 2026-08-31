import { UserEntity } from '../../../../../users/infrastructure/persistence/relational/entities/user.entity';

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
import { newId } from '../../../../../common/id/uuid';

/**
 * 一个 users 行可挂多个身份（provider + providerUid）：
 * 手机号 / 微信 unionid / Apple / Google 都是一条 identity（ADAPTATION_PLAN §3）。
 */
@Entity({
  name: 'user_identity',
})
@Index('uq_user_identity_provider_uid', ['provider', 'providerUid'], {
  unique: true,
})
export class UserIdentityEntity extends EntityRelationalHelper {
  @PrimaryColumn({ type: 'uuid' })
  id: string;

  @BeforeInsert()
  assignId() {
    if (!this.id) {
      this.id = newId();
    }
  }

  @Column({ type: String })
  provider: string;

  @Column({ type: String })
  providerUid: string;

  @Index()
  @Column({ type: Number })
  userId: number;

  @ManyToOne(() => UserEntity, { eager: false, nullable: false })
  @JoinColumn({ name: 'userId' })
  user?: UserEntity;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
