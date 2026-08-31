import { Module } from '@nestjs/common';
import { SocialPostRepository } from '../social-post.repository';
import { SocialPostRelationalRepository } from './repositories/social-post.repository';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SocialPostEntity } from './entities/social-post.entity';

@Module({
  imports: [TypeOrmModule.forFeature([SocialPostEntity])],
  providers: [
    {
      provide: SocialPostRepository,
      useClass: SocialPostRelationalRepository,
    },
  ],
  exports: [SocialPostRepository],
})
export class RelationalSocialPostPersistenceModule {}
