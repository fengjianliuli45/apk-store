import { Profile } from '../../../../domain/profile';
import { ProfileEntity } from '../entities/profile.entity';

export class ProfileMapper {
  static toDomain(raw: ProfileEntity): Profile {
    const domain = new Profile();
    domain.id = raw.id;
    domain.userId = raw.userId;
    domain.sex = raw.sex;
    domain.birthdate = raw.birthdate;
    domain.heightCm = raw.heightCm;
    domain.goal = raw.goal;
    domain.experienceLevel = raw.experienceLevel;
    domain.minutesPerSession = raw.minutesPerSession;
    domain.mealsPerDay = raw.mealsPerDay;
    domain.cookingAccess = raw.cookingAccess;
    domain.targetWeightKg = raw.targetWeightKg;
    domain.injuriesText = raw.injuriesText;
    domain.equipment = raw.equipment ?? [];
    domain.dietaryRestrictions = raw.dietaryRestrictions ?? [];
    domain.bodyDataConsentAt = raw.bodyDataConsentAt;
    domain.bodyDataConsentVersion = raw.bodyDataConsentVersion;
    domain.createdAt = raw.createdAt;
    domain.updatedAt = raw.updatedAt;
    return domain;
  }

  static toPersistence(domain: Profile): ProfileEntity {
    const entity = new ProfileEntity();
    if (domain.id) {
      entity.id = domain.id;
    }
    entity.userId = domain.userId;
    entity.sex = domain.sex ?? null;
    entity.birthdate = domain.birthdate ?? null;
    entity.heightCm = domain.heightCm ?? null;
    entity.goal = domain.goal ?? null;
    entity.experienceLevel = domain.experienceLevel ?? null;
    entity.minutesPerSession = domain.minutesPerSession ?? null;
    entity.mealsPerDay = domain.mealsPerDay ?? null;
    entity.cookingAccess = domain.cookingAccess ?? null;
    entity.targetWeightKg = domain.targetWeightKg ?? null;
    entity.injuriesText = domain.injuriesText ?? null;
    entity.equipment = domain.equipment ?? [];
    entity.dietaryRestrictions = domain.dietaryRestrictions ?? [];
    entity.bodyDataConsentAt = domain.bodyDataConsentAt ?? null;
    entity.bodyDataConsentVersion = domain.bodyDataConsentVersion ?? null;
    entity.createdAt = domain.createdAt;
    entity.updatedAt = domain.updatedAt;
    return entity;
  }
}
