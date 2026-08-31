import {
  // do not remove this comment
  Module,
} from '@nestjs/common';
import { ProfilesService } from './profiles.service';
import { ProfilesController } from './profiles.controller';
import { RelationalProfilePersistenceModule } from './infrastructure/persistence/relational/relational-persistence.module';
import { SyncEventsModule } from '../sync-events/sync-events.module';

@Module({
  imports: [
    // do not remove this comment
    RelationalProfilePersistenceModule,
    SyncEventsModule,
  ],
  controllers: [ProfilesController],
  providers: [ProfilesService],
  exports: [ProfilesService, RelationalProfilePersistenceModule],
})
export class ProfilesModule {}
