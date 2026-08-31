import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { PostCommentEntity } from '../entities/post-comment.entity';
import { NullableType } from '../../../../../utils/types/nullable.type';
import {
  CursorPage,
  decodeCursor,
  toCursorPage,
} from '../../../../../common/pagination/cursor';
import { PostComment } from '../../../../domain/post-comment';
import { PostCommentRepository } from '../../post-comment.repository';
import { PostCommentMapper } from '../mappers/post-comment.mapper';

@Injectable()
export class PostCommentRelationalRepository implements PostCommentRepository {
  constructor(
    @InjectRepository(PostCommentEntity)
    private readonly repo: Repository<PostCommentEntity>,
  ) {}

  async create(
    data: Omit<PostComment, 'id' | 'createdAt' | 'deletedAt'>,
  ): Promise<PostComment> {
    const entity = this.repo.create({
      postId: data.postId,
      authorId: data.authorId,
      body: data.body,
      moderationStatus: data.moderationStatus,
    });
    const saved = await this.repo.save(entity);
    return PostCommentMapper.toDomain(saved);
  }

  async findById(id: string): Promise<NullableType<PostComment>> {
    const entity = await this.repo.findOne({ where: { id } });
    return entity ? PostCommentMapper.toDomain(entity) : null;
  }

  async softDelete(id: string): Promise<void> {
    await this.repo.softDelete({ id });
  }

  async listByPost(
    postId: string,
    limit: number,
    cursor?: string | null,
  ): Promise<CursorPage<PostComment>> {
    const qb = this.repo
      .createQueryBuilder('c')
      .where('c.postId = :postId', { postId })
      .orderBy('c.createdAt', 'ASC')
      .addOrderBy('c.id', 'ASC')
      .take(limit + 1);

    const decoded = decodeCursor(cursor);
    if (decoded) {
      qb.andWhere('(c.createdAt, c.id) > (:t, :i)', {
        t: decoded.t,
        i: decoded.i,
      });
    }

    const rows = await qb.getMany();
    return toCursorPage(
      rows.map((r) => PostCommentMapper.toDomain(r)),
      limit,
      (r) => ({ createdAt: r.createdAt, id: r.id }),
    );
  }
}
