import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

/**
 * 用户训练画像 —— 问卷里相对稳定的部分（性别/生日/身高/目标/水平/器械/时间/饮食限制/伤病）。
 * 会随时间变的体重 / 体脂 / 围度走 body log，不在这里。
 * 高敏身体数据单独存表 + 单独同意（ADAPTATION_PLAN §9.6）。
 */
export class Profile {
  @ApiProperty({ type: String })
  id: string;

  @ApiProperty({ type: Number })
  userId: number;

  @ApiPropertyOptional({ type: String, example: 'male' })
  sex: string | null;

  @ApiPropertyOptional({ type: String, format: 'date', example: '1995-06-01' })
  birthdate: string | null;

  @ApiPropertyOptional({ type: Number, example: 175 })
  heightCm: number | null;

  @ApiPropertyOptional({ type: String, example: 'hypertrophy' })
  goal: string | null;

  @ApiPropertyOptional({ type: String, example: 'beginner' })
  experienceLevel: string | null;

  @ApiPropertyOptional({ type: Number, example: 60 })
  minutesPerSession: number | null;

  @ApiPropertyOptional({ type: Number, example: 3 })
  mealsPerDay: number | null;

  @ApiPropertyOptional({ type: String, example: 'full' })
  cookingAccess: string | null;

  @ApiPropertyOptional({ type: Number, example: 72.5 })
  targetWeightKg: number | null;

  @ApiPropertyOptional({ type: String, example: '右肩偶尔疼' })
  injuriesText: string | null;

  @ApiProperty({ type: [String], example: ['dumbbell', 'bench'] })
  equipment: string[];

  @ApiProperty({ type: [String], example: ['vegetarian'] })
  dietaryRestrictions: string[];

  @ApiPropertyOptional({ type: Date })
  bodyDataConsentAt: Date | null;

  @ApiPropertyOptional({ type: String, example: '2026-01' })
  bodyDataConsentVersion: string | null;

  @ApiProperty()
  createdAt: Date;

  @ApiProperty()
  updatedAt: Date;
}
