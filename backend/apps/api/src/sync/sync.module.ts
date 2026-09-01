import { Module } from '@nestjs/common';
import { SyncController } from './sync.controller';
import { SyncService } from './sync.service';
import { SyncEventsModule } from '../sync-events/sync-events.module';
import { WorkoutSessionsModule } from '../workout-sessions/workout-sessions.module';
import { ProfilesModule } from '../profiles/profiles.module';
import { BodyLogsModule } from '../body-logs/body-logs.module';

@Module({
  imports: [
    SyncEventsModule,
    WorkoutSessionsModule,
    ProfilesModule,
    BodyLogsModule,
  ],
  controllers: [SyncController],
  providers: [SyncService],
})
export class SyncModule {}
