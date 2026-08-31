import { Follow } from '../../../../domain/follow';
import { FollowEntity } from '../entities/follow.entity';

export class FollowMapper {
  static toDomain(raw: FollowEntity): Follow {
    const d = new Follow();
    d.id = raw.id;
    d.followerId = raw.followerId;
    d.followeeId = raw.followeeId;
    d.createdAt = raw.createdAt;
    return d;
  }

  static toPersistence(d: Follow): FollowEntity {
    const e = new FollowEntity();
    if (d.id) {
      e.id = d.id;
    }
    e.followerId = d.followerId;
    e.followeeId = d.followeeId;
    e.createdAt = d.createdAt;
    return e;
  }
}
