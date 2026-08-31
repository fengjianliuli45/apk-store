import { Report } from '../../domain/report';

export abstract class ReportRepository {
  abstract create(
    data: Omit<Report, 'id' | 'createdAt' | 'status'>,
  ): Promise<Report>;

  abstract countOpenByReporterSince(
    reporterId: number,
    since: Date,
  ): Promise<number>;
}
