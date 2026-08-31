import {
  Report,
  ReportStatus,
  ReportTargetType,
} from '../../../../domain/report';
import { ReportEntity } from '../entities/report.entity';

export class ReportMapper {
  static toDomain(raw: ReportEntity): Report {
    const d = new Report();
    d.id = raw.id;
    d.reporterId = raw.reporterId;
    d.targetType = raw.targetType as ReportTargetType;
    d.targetId = raw.targetId;
    d.reason = raw.reason;
    d.detail = raw.detail;
    d.status = raw.status as ReportStatus;
    d.createdAt = raw.createdAt;
    return d;
  }

  static toPersistence(d: Report): ReportEntity {
    const e = new ReportEntity();
    if (d.id) {
      e.id = d.id;
    }
    e.reporterId = d.reporterId;
    e.targetType = d.targetType;
    e.targetId = d.targetId;
    e.reason = d.reason;
    e.detail = d.detail ?? null;
    e.status = d.status;
    e.createdAt = d.createdAt;
    return e;
  }
}
