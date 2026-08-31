import { Module } from '@nestjs/common';
import { FollowRepository } from '../follow.repository';
import { FollowRelationalRepository } from './repositories/follow.repository';
import { TypeOrmModule } from '@nestjs/typeorm';
import { FollowEntity } from './entities/follow.entity';

@Module({
  imports: [TypeOrmModule.forFeature([FollowEntity])],
  providers: [
    {
      provide: FollowRepository,
      useClass: FollowRelationalRepository,
    },
  ],
  exports: [FollowRepository],
})
export class RelationalFollowPersistenceModule {}
