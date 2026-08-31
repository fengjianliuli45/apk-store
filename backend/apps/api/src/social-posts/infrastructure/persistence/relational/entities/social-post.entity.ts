import {
  BeforeInsert,
  Column,
  CreateDateColumn,
  DeleteDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryColumn,
} from 'typeorm';
import { EntityRelationalHelper } from '../../../../../utils/relational-entity-helper';
import { UserEntity } from '../../../../../users/infrastructure/persistence/relational/entities/user.entity';
import { newId } from '../../../../../common/id/uuid';

@Entity({ name: 'social_post' })
@Index('IDX_social_post_author_created', ['authorId', 'createdAt'])
@Index('IDX_social_post_created', ['createdAt'])
export class SocialPostEntity extends EntityRelationalHelper {
  @PrimaryColumn({ type: 'uuid' })
  id: string;

  @BeforeInsert()
  assignId() {
    if (!this.id) {
      this.id = newId();
    }
  }

  @Column({ type: Number })
  authorId: number;

  @ManyToOne(() => UserEntity, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'authorId' })
  author?: UserEntity;

  @Column({ type: String, default: 'text' })
  kind: string;

  @Column({ type: 'text', default: '' })
  body: string;

  @Column({ type: 'jsonb', default: () => "'[]'" })
  mediaIds: string[];

  @Column({ type: String, nullable: true })
  refType: string | null;

  @Column({ type: String, nullable: true })
  refId: string | null;

  @Column({ type: String, default: 'public' })
  visibility: string;

  @Column({ type: Number, default: 0 })
  likeCount: number;

  @Column({ type: Number, default: 0 })
  commentCount: number;

  @Column({ type: String, default: 'pending' })
  moderationStatus: string;

  @CreateDateColumn()
  createdAt: Date;

  @DeleteDateColumn()
  deletedAt: Date | null;
}
