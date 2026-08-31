import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { MoreThanOrEqual, Repository } from 'typeorm';
import { ReportEntity } from '../entities/report.entity';
import { Report } from '../../../../domain/report';
import { ReportRepository } from '../../report.repository';
import { ReportMapper } from '../mappers/report.mapper';

@Injectable()
export class ReportRelationalRepository implements ReportRepository {
  constructor(
    @InjectRepository(ReportEntity)
    private readonly repo: Repository<ReportEntity>,
  ) {}

  async create(
    data: Omit<Report, 'id' | 'createdAt' | 'status'>,
  ): Promise<Report> {
    const entity = this.repo.create({
      reporterId: data.reporterId,
      targetType: data.targetType,
      targetId: data.targetId,
      reason: data.reason,
      detail: data.detail ?? null,
    });
    const saved = await this.repo.save(entity);
    return ReportMapper.toDomain(saved);
  }

  countOpenByReporterSince(reporterId: number, since: Date): Promise<number> {
    return this.repo.countBy({
      reporterId,
      createdAt: MoreThanOrEqual(since),
    });
  }
}
