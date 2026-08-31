import { Module } from '@nestjs/common';
import { ReportRepository } from '../report.repository';
import { ReportRelationalRepository } from './repositories/report.repository';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ReportEntity } from './entities/report.entity';

@Module({
  imports: [TypeOrmModule.forFeature([ReportEntity])],
  providers: [
    {
      provide: ReportRepository,
      useClass: ReportRelationalRepository,
    },
  ],
  exports: [ReportRepository],
})
export class RelationalReportPersistenceModule {}
