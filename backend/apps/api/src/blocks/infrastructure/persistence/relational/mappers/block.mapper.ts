import { Block } from '../../../../domain/block';
import { BlockEntity } from '../entities/block.entity';

export class BlockMapper {
  static toDomain(raw: BlockEntity): Block {
    const d = new Block();
    d.id = raw.id;
    d.blockerId = raw.blockerId;
    d.blockedId = raw.blockedId;
    d.createdAt = raw.createdAt;
    return d;
  }

  static toPersistence(d: Block): BlockEntity {
    const e = new BlockEntity();
    if (d.id) {
      e.id = d.id;
    }
    e.blockerId = d.blockerId;
    e.blockedId = d.blockedId;
    e.createdAt = d.createdAt;
    return e;
  }
}
