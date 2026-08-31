import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, IsNull, Repository } from 'typeorm';
import { NotificationEntity } from '../entities/notification.entity';
import {
  CursorPage,
  decodeCursor,
  toCursorPage,
} from '../../../../../common/pagination/cursor';
import { Notification } from '../../../../domain/notification';
import { NotificationRepository } from '../../notification.repository';
import { NotificationMapper } from '../mappers/notification.mapper';

@Injectable()
export class NotificationRelationalRepository implements NotificationRepository {
  constructor(
    @InjectRepository(NotificationEntity)
    private readonly repo: Repository<NotificationEntity>,
  ) {}

  async create(
    data: Omit<Notification, 'id' | 'createdAt'>,
  ): Promise<Notification> {
    const entity = this.repo.create(
      NotificationMapper.toPersistence(data as Notification),
    );
    const saved = await this.repo.save(entity);
    return NotificationMapper.toDomain(saved);
  }

  async listByUser(
    userId: number,
    opts: { limit: number; cursor?: string | null; unreadOnly?: boolean },
  ): Promise<CursorPage<Notification>> {
    const qb = this.repo
      .createQueryBuilder('n')
      .where('n.userId = :userId', { userId })
      .orderBy('n.createdAt', 'DESC')
      .addOrderBy('n.id', 'DESC')
      .take(opts.limit + 1);

    if (opts.unreadOnly) {
      qb.andWhere('n.readAt IS NULL');
    }

    const decoded = decodeCursor(opts.cursor);
    if (decoded) {
      qb.andWhere('(n.createdAt, n.id) < (:t, :i)', {
        t: decoded.t,
        i: decoded.i,
      });
    }

    const rows = await qb.getMany();
    return toCursorPage(
      rows.map((r) => NotificationMapper.toDomain(r)),
      opts.limit,
      (r) => ({ createdAt: r.createdAt, id: r.id }),
    );
  }

  unreadCount(userId: number): Promise<number> {
    return this.repo.count({ where: { userId, readAt: IsNull() } });
  }

  async markRead(userId: number, ids: string[]): Promise<number> {
    const where = ids.length > 0 ? { userId, id: In(ids) } : { userId };
    const res = await this.repo.update(
      { ...where, readAt: IsNull() },
      { readAt: new Date() },
    );
    return res.affected ?? 0;
  }
}
