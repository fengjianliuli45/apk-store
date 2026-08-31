import { Injectable, NotFoundException } from '@nestjs/common';
import { NullableType } from '../utils/types/nullable.type';
import { ProfileRepository } from './infrastructure/persistence/profile.repository';
import { Profile } from './domain/profile';
import { SyncEmitterService } from '../sync-events/sync-emitter.service';
import { UpsertProfileDto } from './dto/upsert-profile.dto';

export type WriteContext = {
  clientEventId?: string | null;
  occurredAt?: Date;
};

@Injectable()
export class ProfilesService {
  constructor(
    private readonly profileRepository: ProfileRepository,
    private readonly sync: SyncEmitterService,
  ) {}

  findByUserId(userId: number): Promise<NullableType<Profile>> {
    return this.profileRepository.findByUserId(userId);
  }

  async getByUserIdOrFail(userId: number): Promise<Profile> {
    const profile = await this.profileRepository.findByUserId(userId);
    if (!profile) {
      throw new NotFoundException({ errors: { profile: 'notCreated' } });
    }
    return profile;
  }

  /** PUT 语义：没有就建，有就按传入字段部分更新。 */
  async upsertForUser(
    userId: number,
    dto: UpsertProfileDto,
    ctx?: WriteContext,
  ): Promise<Profile> {
    const patch = this.toPatch(dto);
    const existing = await this.profileRepository.findByUserId(userId);

    let result: Profile;
    if (!existing) {
      result = await this.profileRepository.create({
        userId,
        sex: null,
        birthdate: null,
        heightCm: null,
        goal: null,
        experienceLevel: null,
        minutesPerSession: null,
        mealsPerDay: null,
        cookingAccess: null,
        targetWeightKg: null,
        injuriesText: null,
        equipment: [],
        dietaryRestrictions: [],
        bodyDataConsentAt: null,
        bodyDataConsentVersion: null,
        ...patch,
      });
    } else {
      result =
        (await this.profileRepository.update(existing.id, patch)) ?? existing;
    }

    await this.sync.emit({
      userId,
      entityType: 'profile',
      entityId: result.id,
      op: existing ? 'update' : 'create',
      payload: result as unknown as Record<string, unknown>,
      clientEventId: ctx?.clientEventId ?? null,
      occurredAt: ctx?.occurredAt,
    });

    return result;
  }

  remove(id: Profile['id']): Promise<void> {
    return this.profileRepository.remove(id);
  }

  private toPatch(dto: UpsertProfileDto): Partial<Profile> {
    const patch: Partial<Profile> = {};
    const keys = [
      'sex',
      'birthdate',
      'heightCm',
      'goal',
      'experienceLevel',
      'minutesPerSession',
      'mealsPerDay',
      'cookingAccess',
      'targetWeightKg',
      'injuriesText',
      'equipment',
      'dietaryRestrictions',
    ] as const;

    for (const key of keys) {
      if (dto[key] !== undefined) {
        (patch as Record<string, unknown>)[key] = dto[key];
      }
    }

    if (dto.bodyDataConsent === true) {
      patch.bodyDataConsentAt = new Date();
      patch.bodyDataConsentVersion = dto.bodyDataConsentVersion ?? null;
    } else if (dto.bodyDataConsent === false) {
      patch.bodyDataConsentAt = null;
      patch.bodyDataConsentVersion = null;
    }

    return patch;
  }
}
