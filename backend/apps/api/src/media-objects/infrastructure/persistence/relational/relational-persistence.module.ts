import { Module } from '@nestjs/common';
import { MediaObjectRepository } from '../media-object.repository';
import { MediaObjectRelationalRepository } from './repositories/media-object.repository';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MediaObjectEntity } from './entities/media-object.entity';

@Module({
  imports: [TypeOrmModule.forFeature([MediaObjectEntity])],
  providers: [
    {
      provide: MediaObjectRepository,
      useClass: MediaObjectRelationalRepository,
    },
  ],
  exports: [MediaObjectRepository],
})
export class RelationalMediaObjectPersistenceModule {}
