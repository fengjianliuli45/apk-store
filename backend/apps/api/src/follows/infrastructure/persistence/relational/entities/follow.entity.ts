import {
  BeforeInsert,
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryColumn,
} from 'typeorm';
import { EntityRelationalHelper } from '../../../../../utils/relational-entity-helper';
import { newId } from '../../../../../common/id/uuid';

@Entity({ name: 'follow' })
@Index('uq_follow_pair', ['followerId', 'followeeId'], { unique: true })
@Index('IDX_follow_followee', ['followeeId'])
export class FollowEntity extends EntityRelationalHelper {
  @PrimaryColumn({ type: 'uuid' })
  id: string;

  @BeforeInsert()
  assignId() {
    if (!this.id) {
      this.id = newId();
    }
  }

  @Column({ type: Number })
  followerId: number;

  @Column({ type: Number })
  followeeId: number;

  @CreateDateColumn()
  createdAt: Date;
}
