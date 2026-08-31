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

@Entity({ name: 'block' })
@Index('uq_block_pair', ['blockerId', 'blockedId'], { unique: true })
export class BlockEntity extends EntityRelationalHelper {
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
  blockerId: number;

  @Column({ type: Number })
  blockedId: number;

  @CreateDateColumn()
  createdAt: Date;
}
