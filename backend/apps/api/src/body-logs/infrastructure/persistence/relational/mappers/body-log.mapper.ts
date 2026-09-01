import { BodyLog } from '../../../../domain/body-log';
import { BodyLogEntity } from '../entities/body-log.entity';

export class BodyLogMapper {
  static toDomain(raw: BodyLogEntity): BodyLog {
    const d = new BodyLog();
    d.id = raw.id;
    d.userId = raw.userId;
    d.measuredOn = raw.measuredOn;
    d.weightKg = raw.weightKg;
    d.bodyFatPct = raw.bodyFatPct;
    d.waistCm = raw.waistCm;
    d.armCm = raw.armCm;
    d.thighCm = raw.thighCm;
    d.note = raw.note;
    d.createdAt = raw.createdAt;
    d.updatedAt = raw.updatedAt;
    return d;
  }

  static toPersistence(d: BodyLog): BodyLogEntity {
    const e = new BodyLogEntity();
    if (d.id) {
      e.id = d.id;
    }
    e.userId = d.userId;
    e.measuredOn = d.measuredOn;
    e.weightKg = d.weightKg ?? null;
    e.bodyFatPct = d.bodyFatPct ?? null;
    e.waistCm = d.waistCm ?? null;
    e.armCm = d.armCm ?? null;
    e.thighCm = d.thighCm ?? null;
    e.note = d.note ?? null;
    e.createdAt = d.createdAt;
    e.updatedAt = d.updatedAt;
    return e;
  }
}
