import { Module } from '@nestjs/common';
import { PlanVersionRepository } from '../plan-version.repository';
import { PlanVersionRelationalRepository } from './repositories/plan-version.repository';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PlanVersionEntity } from './entities/plan-version.entity';

@Module({
  imports: [TypeOrmModule.forFeature([PlanVersionEntity])],
  providers: [
    {
      provide: PlanVersionRepository,
      useClass: PlanVersionRelationalRepository,
    },
  ],
  exports: [PlanVersionRepository],
})
export class RelationalPlanVersionPersistenceModule {}
