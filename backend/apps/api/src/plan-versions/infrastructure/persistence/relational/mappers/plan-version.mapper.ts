import { PlanVersion } from '../../../../domain/plan-version';
import { PlanVersionEntity } from '../entities/plan-version.entity';

export class PlanVersionMapper {
  static toDomain(raw: PlanVersionEntity): PlanVersion {
    const domain = new PlanVersion();
    domain.id = raw.id;
    domain.planId = raw.planId;
    domain.versionNumber = raw.versionNumber;
    domain.plannerVersion = raw.plannerVersion;
    domain.generatedBy = raw.generatedBy;
    domain.inputSnapshot = raw.inputSnapshot;
    domain.planJson = raw.planJson;
    domain.changeReason = raw.changeReason;
    domain.createdAt = raw.createdAt;
    return domain;
  }

  static toPersistence(domain: PlanVersion): PlanVersionEntity {
    const entity = new PlanVersionEntity();
    if (domain.id) {
      entity.id = domain.id;
    }
    entity.planId = domain.planId;
    entity.versionNumber = domain.versionNumber;
    entity.plannerVersion = domain.plannerVersion;
    entity.generatedBy = domain.generatedBy;
    entity.inputSnapshot = domain.inputSnapshot;
    entity.planJson = domain.planJson;
    entity.changeReason = domain.changeReason ?? null;
    entity.createdAt = domain.createdAt;
    return entity;
  }
}
