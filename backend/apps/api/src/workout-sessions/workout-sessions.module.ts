import { Module } from '@nestjs/common';
import { WorkoutSessionsService } from './workout-sessions.service';
import { WorkoutSessionsController } from './workout-sessions.controller';
import { RelationalWorkoutSessionPersistenceModule } from './infrastructure/persistence/relational/relational-persistence.module';
import { RelationalWorkoutSetPersistenceModule } from '../workout-sets/infrastructure/persistence/relational/relational-persistence.module';
import { SyncEventsModule } from '../sync-events/sync-events.module';

@Module({
  imports: [
    RelationalWorkoutSessionPersistenceModule,
    RelationalWorkoutSetPersistenceModule,
    SyncEventsModule,
  ],
  controllers: [WorkoutSessionsController],
  providers: [WorkoutSessionsService],
  exports: [WorkoutSessionsService],
})
export class WorkoutSessionsModule {}
