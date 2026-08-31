import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export const NOTIFICATION_CATEGORIES = [
  'workout_reminder',
  'plan_ready',
  'check_in',
  'social',
  'chat',
  'system',
] as const;

export type NotificationCategory = (typeof NOTIFICATION_CATEGORIES)[number];

/** 每用户一条。categories 缺省视为 true（opt-out 模型）。 */
export class NotificationPreference {
  @ApiProperty({ type: String })
  id: string;

  @ApiProperty({ type: Number })
  userId: number;

  @ApiProperty({ type: Boolean, default: true })
  pushEnabled: boolean;

  @ApiProperty({
    type: 'object',
    additionalProperties: { type: 'boolean' },
    description: '按分类关推送；缺省 = 开',
  })
  categories: Record<string, boolean>;

  @ApiPropertyOptional({
    type: Number,
    example: 22,
    description: '免打扰起点小时 0-23',
  })
  quietHoursStart: number | null;

  @ApiPropertyOptional({
    type: Number,
    example: 8,
    description: '免打扰终点小时 0-23',
  })
  quietHoursEnd: number | null;

  @ApiProperty()
  updatedAt: Date;
}
