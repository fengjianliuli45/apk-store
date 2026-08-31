import { Module } from '@nestjs/common';
import { PostLikeRepository } from '../post-like.repository';
import { PostLikeRelationalRepository } from './repositories/post-like.repository';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PostLikeEntity } from './entities/post-like.entity';

@Module({
  imports: [TypeOrmModule.forFeature([PostLikeEntity])],
  providers: [
    {
      provide: PostLikeRepository,
      useClass: PostLikeRelationalRepository,
    },
  ],
  exports: [PostLikeRepository],
})
export class RelationalPostLikePersistenceModule {}
