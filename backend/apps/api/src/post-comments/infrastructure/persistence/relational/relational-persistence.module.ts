import { Module } from '@nestjs/common';
import { PostCommentRepository } from '../post-comment.repository';
import { PostCommentRelationalRepository } from './repositories/post-comment.repository';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PostCommentEntity } from './entities/post-comment.entity';

@Module({
  imports: [TypeOrmModule.forFeature([PostCommentEntity])],
  providers: [
    {
      provide: PostCommentRepository,
      useClass: PostCommentRelationalRepository,
    },
  ],
  exports: [PostCommentRepository],
})
export class RelationalPostCommentPersistenceModule {}
