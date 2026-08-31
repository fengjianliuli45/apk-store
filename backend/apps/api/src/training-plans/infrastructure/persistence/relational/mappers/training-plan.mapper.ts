import {
  TrainingPlan,
  TrainingPlanStatus,
} from '../../../../domain/training-plan';
import { TrainingPlanEntity } from '../entities/training-plan.entity';

export class TrainingPlanMapper {
  static toDomain(raw: TrainingPlanEntity): TrainingPlan {
    const domain = new TrainingPlan();
    domain.id = raw.id;
    domain.userId = raw.userId;
    domain.status = raw.status as TrainingPlanStatus;
    domain.plannerVersion = raw.plannerVersion;
    domain.generatedBy = raw.generatedBy;
    domain.currentVersionNumber = raw.currentVersionNumber;
    domain.currentVersionId = raw.currentVersionId;
    domain.createdAt = raw.createdAt;
    domain.updatedAt = raw.updatedAt;
    return domain;
  }

  static toPersistence(domain: TrainingPlan): TrainingPlanEntity {
    const entity = new TrainingPlanEntity();
    if (domain.id) {
      entity.id = domain.id;
    }
    entity.userId = domain.userId;
    entity.status = domain.status;
    entity.plannerVersion = domain.plannerVersion;
    entity.generatedBy = domain.generatedBy;
    entity.currentVersionNumber = domain.currentVersionNumber;
    entity.currentVersionId = domain.currentVersionId ?? null;
    entity.createdAt = domain.createdAt;
    entity.updatedAt = domain.updatedAt;
    return entity;
  }
}
