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

@Entity({ name: 'media_object' })
@Index('IDX_media_object_user', ['userId', 'createdAt'])
export class MediaObjectEntity extends EntityRelationalHelper {
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

  @Column({ type: String })
  purpose: string;

  @Index({ unique: true })
  @Column({ type: String })
  storageKey: string;

  @Column({ type: String })
  contentType: string;

  @Column({ type: 'int' })
  declaredSize: number;

  @Column({ type: 'int', nullable: true })
  actualSize: number | null;

  @Column({ type: String, default: 'pending' })
  status: string;

  @Column({ type: String, default: 'pending' })
  moderationStatus: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
