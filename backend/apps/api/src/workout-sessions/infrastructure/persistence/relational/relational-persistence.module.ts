import { Module } from '@nestjs/common';
import { WorkoutSessionRepository } from '../workout-session.repository';
import { WorkoutSessionRelationalRepository } from './repositories/workout-session.repository';
import { TypeOrmModule } from '@nestjs/typeorm';
import { WorkoutSessionEntity } from './entities/workout-session.entity';

@Module({
  imports: [TypeOrmModule.forFeature([WorkoutSessionEntity])],
  providers: [
    {
      provide: WorkoutSessionRepository,
      useClass: WorkoutSessionRelationalRepository,
    },
  ],
  exports: [WorkoutSessionRepository],
})
export class RelationalWorkoutSessionPersistenceModule {}
