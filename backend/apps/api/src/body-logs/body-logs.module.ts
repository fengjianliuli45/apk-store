import { Module } from '@nestjs/common';
import { BodyLogsService } from './body-logs.service';
import { BodyLogsController } from './body-logs.controller';
import { RelationalBodyLogPersistenceModule } from './infrastructure/persistence/relational/relational-persistence.module';
import { SyncEventsModule } from '../sync-events/sync-events.module';

@Module({
  imports: [RelationalBodyLogPersistenceModule, SyncEventsModule],
  controllers: [BodyLogsController],
  providers: [BodyLogsService],
  exports: [BodyLogsService],
})
export class BodyLogsModule {}
