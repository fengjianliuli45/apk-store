import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, SelectQueryBuilder } from 'typeorm';
import { SocialPostEntity } from '../entities/social-post.entity';
import { NullableType } from '../../../../../utils/types/nullable.type';
import {
  CursorPage,
  decodeCursor,
  toCursorPage,
} from '../../../../../common/pagination/cursor';
import { SocialPost } from '../../../../domain/social-post';
import { SocialPostRepository } from '../../social-post.repository';
import { SocialPostMapper } from '../mappers/social-post.mapper';

@Injectable()
export class SocialPostRelationalRepository implements SocialPostRepository {
  constructor(
    @InjectRepository(SocialPostEntity)
    private readonly repo: Repository<SocialPostEntity>,
  ) {}

  async create(
    data: Omit<
      SocialPost,
      'id' | 'createdAt' | 'deletedAt' | 'likeCount' | 'commentCount'
    >,
  ): Promise<SocialPost> {
    const entity = this.repo.create({
      authorId: data.authorId,
      kind: data.kind,
      body: data.body,
      mediaIds: data.mediaIds ?? [],
      refType: data.refType ?? null,
      refId: data.refId ?? null,
      visibility: data.visibility,
      moderationStatus: data.moderationStatus,
    });
    const saved = await this.repo.save(entity);
    return SocialPostMapper.toDomain(saved);
  }

  async findById(id: string): Promise<NullableType<SocialPost>> {
    const entity = await this.repo.findOne({ where: { id } });
    return entity ? SocialPostMapper.toDomain(entity) : null;
  }

  async softDelete(id: string): Promise<void> {
    await this.repo.softDelete({ id });
  }

  async bumpCounters(
    id: string,
    delta: { like?: number; comment?: number },
  ): Promise<void> {
    if (delta.like) {
      await this.repo.increment({ id }, 'likeCount', delta.like);
    }
    if (delta.comment) {
      await this.repo.increment({ id }, 'commentCount', delta.comment);
    }
  }

  listByAuthor(
    authorId: number,
    limit: number,
    cursor?: string | null,
  ): Promise<CursorPage<SocialPost>> {
    return this.page(
      this.repo
        .createQueryBuilder('p')
        .where('p.authorId = :authorId', { authorId }),
      limit,
      cursor,
    );
  }

  feed(
    authorIds: number[],
    excludeAuthorIds: number[],
    limit: number,
    cursor?: string | null,
  ): Promise<CursorPage<SocialPost>> {
    if (authorIds.length === 0) {
      return Promise.resolve({ data: [], nextCursor: null });
    }
    const qb = this.repo
      .createQueryBuilder('p')
      .where('p.authorId IN (:...authorIds)', { authorIds });
    if (excludeAuthorIds.length > 0) {
      qb.andWhere('p.authorId NOT IN (:...excludeAuthorIds)', {
        excludeAuthorIds,
      });
    }
    return this.page(qb, limit, cursor);
  }

  private async page(
    qb: SelectQueryBuilder<SocialPostEntity>,
    limit: number,
    cursor?: string | null,
  ): Promise<CursorPage<SocialPost>> {
    qb.orderBy('p.createdAt', 'DESC')
      .addOrderBy('p.id', 'DESC')
      .take(limit + 1);
    const decoded = decodeCursor(cursor);
    if (decoded) {
      qb.andWhere('(p.createdAt, p.id) < (:t, :i)', {
        t: decoded.t,
        i: decoded.i,
      });
    }
    const rows = await qb.getMany();
    return toCursorPage(
      rows.map((r) => SocialPostMapper.toDomain(r)),
      limit,
      (r) => ({ createdAt: r.createdAt, id: r.id }),
    );
  }
}
