import { Injectable } from '@nestjs/common';
import { NotificationPreferenceRepository } from './infrastructure/persistence/notification-preference.repository';
import { NotificationPreference } from './domain/notification-preference';
import { UpdatePreferencesDto } from './dto/update-preferences.dto';

@Injectable()
export class NotificationPreferencesService {
  constructor(private readonly repo: NotificationPreferenceRepository) {}

  /** 没有行也返回一个默认（不落库）。读场景用。 */
  async getOrDefault(userId: number): Promise<NotificationPreference> {
    const existing = await this.repo.findByUserId(userId);
    if (existing) {
      return existing;
    }
    const now = new Date();
    return {
      id: '',
      userId,
      pushEnabled: true,
      categories: {},
      quietHoursStart: null,
      quietHoursEnd: null,
      updatedAt: now,
    };
  }

  private async getOrCreate(userId: number): Promise<NotificationPreference> {
    const existing = await this.repo.findByUserId(userId);
    if (existing) {
      return existing;
    }
    return this.repo.create({
      userId,
      pushEnabled: true,
      categories: {},
      quietHoursStart: null,
      quietHoursEnd: null,
    });
  }

  async update(
    userId: number,
    dto: UpdatePreferencesDto,
  ): Promise<NotificationPreference> {
    const pref = await this.getOrCreate(userId);
    const patch: Partial<NotificationPreference> = {};
    if (dto.pushEnabled !== undefined) {
      patch.pushEnabled = dto.pushEnabled;
    }
    if (dto.categories !== undefined) {
      patch.categories = { ...pref.categories, ...dto.categories };
    }
    if (dto.quietHoursStart !== undefined) {
      patch.quietHoursStart = dto.quietHoursStart;
    }
    if (dto.quietHoursEnd !== undefined) {
      patch.quietHoursEnd = dto.quietHoursEnd;
    }
    const updated = await this.repo.update(pref.id, patch);
    return updated ?? pref;
  }
}
