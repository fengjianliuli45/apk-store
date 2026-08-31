import {
  WorkoutSession,
  WorkoutSessionStatus,
} from '../../../../domain/workout-session';
import { WorkoutSessionEntity } from '../entities/workout-session.entity';

export class WorkoutSessionMapper {
  static toDomain(raw: WorkoutSessionEntity): WorkoutSession {
    const domain = new WorkoutSession();
    domain.id = raw.id;
    domain.userId = raw.userId;
    domain.planVersionId = raw.planVersionId;
    domain.planDayIndex = raw.planDayIndex;
    domain.sessionType = raw.sessionType;
    domain.scheduledDate = raw.scheduledDate;
    domain.status = raw.status as WorkoutSessionStatus;
    domain.startedAt = raw.startedAt;
    domain.completedAt = raw.completedAt;
    domain.notes = raw.notes;
    domain.createdAt = raw.createdAt;
    domain.updatedAt = raw.updatedAt;
    return domain;
  }

  static toPersistence(domain: WorkoutSession): WorkoutSessionEntity {
    const entity = new WorkoutSessionEntity();
    if (domain.id) {
      entity.id = domain.id;
    }
    entity.userId = domain.userId;
    entity.planVersionId = domain.planVersionId ?? null;
    entity.planDayIndex = domain.planDayIndex ?? null;
    entity.sessionType = domain.sessionType;
    entity.scheduledDate = domain.scheduledDate ?? null;
    entity.status = domain.status;
    entity.startedAt = domain.startedAt ?? null;
    entity.completedAt = domain.completedAt ?? null;
    entity.notes = domain.notes ?? null;
    entity.createdAt = domain.createdAt;
    entity.updatedAt = domain.updatedAt;
    return entity;
  }
}
