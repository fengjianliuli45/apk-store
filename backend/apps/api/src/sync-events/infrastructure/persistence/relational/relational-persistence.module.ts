import { Module } from '@nestjs/common';
import { SyncEventRepository } from '../sync-event.repository';
import { SyncEventRelationalRepository } from './repositories/sync-event.repository';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SyncEventEntity } from './entities/sync-event.entity';

@Module({
  imports: [TypeOrmModule.forFeature([SyncEventEntity])],
  providers: [
    {
      provide: SyncEventRepository,
      useClass: SyncEventRelationalRepository,
    },
  ],
  exports: [SyncEventRepository],
})
export class RelationalSyncEventPersistenceModule {}
