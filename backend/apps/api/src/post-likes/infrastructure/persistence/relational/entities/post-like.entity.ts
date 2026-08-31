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
import { SocialPostEntity } from '../../../../../social-posts/infrastructure/persistence/relational/entities/social-post.entity';
import { newId } from '../../../../../common/id/uuid';

@Entity({ name: 'post_like' })
@Index('uq_post_like_post_user', ['postId', 'userId'], { unique: true })
export class PostLikeEntity extends EntityRelationalHelper {
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
  userId: number;

  @CreateDateColumn()
  createdAt: Date;
}
