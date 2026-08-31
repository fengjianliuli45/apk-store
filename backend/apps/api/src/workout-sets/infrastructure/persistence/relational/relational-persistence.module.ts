import { Module } from '@nestjs/common';
import { WorkoutSetRepository } from '../workout-set.repository';
import { WorkoutSetRelationalRepository } from './repositories/workout-set.repository';
import { TypeOrmModule } from '@nestjs/typeorm';
import { WorkoutSetEntity } from './entities/workout-set.entity';

@Module({
  imports: [TypeOrmModule.forFeature([WorkoutSetEntity])],
  providers: [
    {
      provide: WorkoutSetRepository,
      useClass: WorkoutSetRelationalRepository,
    },
  ],
  exports: [WorkoutSetRepository],
})
export class RelationalWorkoutSetPersistenceModule {}
