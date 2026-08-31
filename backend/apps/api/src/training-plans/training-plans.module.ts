import { Module } from '@nestjs/common';
import { TrainingPlansService } from './training-plans.service';
import { TrainingPlansController } from './training-plans.controller';
import { RelationalTrainingPlanPersistenceModule } from './infrastructure/persistence/relational/relational-persistence.module';
import { RelationalPlanVersionPersistenceModule } from '../plan-versions/infrastructure/persistence/relational/relational-persistence.module';

@Module({
  imports: [
    RelationalTrainingPlanPersistenceModule,
    RelationalPlanVersionPersistenceModule,
  ],
  controllers: [TrainingPlansController],
  providers: [TrainingPlansService],
  exports: [TrainingPlansService],
})
export class TrainingPlansModule {}
