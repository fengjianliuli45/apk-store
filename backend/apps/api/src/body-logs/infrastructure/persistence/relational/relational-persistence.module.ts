import { Module } from '@nestjs/common';
import { BodyLogRepository } from '../body-log.repository';
import { BodyLogRelationalRepository } from './repositories/body-log.repository';
import { TypeOrmModule } from '@nestjs/typeorm';
import { BodyLogEntity } from './entities/body-log.entity';

@Module({
  imports: [TypeOrmModule.forFeature([BodyLogEntity])],
  providers: [
    {
      provide: BodyLogRepository,
      useClass: BodyLogRelationalRepository,
    },
  ],
  exports: [BodyLogRepository],
})
export class RelationalBodyLogPersistenceModule {}
