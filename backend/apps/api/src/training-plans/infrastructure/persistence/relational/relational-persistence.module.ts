import { Module } from '@nestjs/common';
import { TrainingPlanRepository } from '../training-plan.repository';
import { TrainingPlanRelationalRepository } from './repositories/training-plan.repository';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TrainingPlanEntity } from './entities/training-plan.entity';

@Module({
  imports: [TypeOrmModule.forFeature([TrainingPlanEntity])],
  providers: [
    {
      provide: TrainingPlanRepository,
      useClass: TrainingPlanRelationalRepository,
    },
  ],
  exports: [TrainingPlanRepository],
})
export class RelationalTrainingPlanPersistenceModule {}
