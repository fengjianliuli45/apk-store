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
import { SocialPostEntity } from '../../../../../social-posts/infrastructure/persistence/relational/entities/social-post.entity';
import { UserEntity } from '../../../../../users/infrastructure/persistence/relational/entities/user.entity';
import { newId } from '../../../../../common/id/uuid';

@Entity({ name: 'post_comment' })
@Index('IDX_post_comment_post_created', ['postId', 'createdAt'])
export class PostCommentEntity extends EntityRelationalHelper {
  @PrimaryColumn({ type: 'uuid' })
  id: string;

  @BeforeInsert()
  assignId() {
    if (!this.id) {
      this.id = newId();
    }
  }

  @Column({ type: 'uuid' })
  postId: string;

  @ManyToOne(() => SocialPostEntity, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'postId' })
  post?: SocialPostEntity;

  @Column({ type: Number })
  authorId: number;

  @ManyToOne(() => UserEntity, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'authorId' })
  author?: UserEntity;

  @Column({ type: 'text' })
  body: string;

  @Column({ type: String, default: 'pending' })
  moderationStatus: string;

  @CreateDateColumn()
  createdAt: Date;

  @DeleteDateColumn()
  deletedAt: Date | null;
}
