import { WorkoutSet } from '../../../../domain/workout-set';
import { WorkoutSetEntity } from '../entities/workout-set.entity';

export class WorkoutSetMapper {
  static toDomain(raw: WorkoutSetEntity): WorkoutSet {
    const domain = new WorkoutSet();
    domain.id = raw.id;
    domain.sessionId = raw.sessionId;
    domain.exerciseKey = raw.exerciseKey;
    domain.exerciseName = raw.exerciseName;
    domain.setIndex = raw.setIndex;
    domain.reps = raw.reps;
    domain.weightKg = raw.weightKg;
    domain.rir = raw.rir;
    domain.isWarmup = raw.isWarmup;
    domain.completedAt = raw.completedAt;
    domain.createdAt = raw.createdAt;
    return domain;
  }

  static toPersistence(domain: WorkoutSet): WorkoutSetEntity {
    const entity = new WorkoutSetEntity();
    if (domain.id) {
      entity.id = domain.id;
    }
    entity.sessionId = domain.sessionId;
    entity.exerciseKey = domain.exerciseKey;
    entity.exerciseName = domain.exerciseName;
    entity.setIndex = domain.setIndex;
    entity.reps = domain.reps ?? null;
    entity.weightKg = domain.weightKg ?? null;
    entity.rir = domain.rir ?? null;
    entity.isWarmup = domain.isWarmup ?? false;
    entity.completedAt = domain.completedAt ?? null;
    entity.createdAt = domain.createdAt;
    return entity;
  }
}
