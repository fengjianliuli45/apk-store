import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

/**
 * 一次身体测量（称重 / 体脂 / 围度）。喂给端上引擎的 review_cycle 做趋势判断。
 * 高敏身体数据，同意开关在 profile.bodyDataConsent（ADAPTATION_PLAN §9.6）。
 */
export class BodyLog {
  @ApiProperty({ type: String })
  id: string;

  @ApiProperty({ type: Number })
  userId: number;

  @ApiProperty({ type: String, format: 'date', example: '2026-09-01' })
  measuredOn: string;

  @ApiPropertyOptional({ type: Number, example: 72.4 })
  weightKg: number | null;

  @ApiPropertyOptional({ type: Number, example: 18.2, description: '体脂率 %' })
  bodyFatPct: number | null;

  @ApiPropertyOptional({ type: Number, example: 80, description: '腰围 cm' })
  waistCm: number | null;

  @ApiPropertyOptional({ type: Number, example: 40, description: '臂围 cm' })
  armCm: number | null;

  @ApiPropertyOptional({ type: Number, example: 58, description: '大腿围 cm' })
  thighCm: number | null;

  @ApiPropertyOptional({ type: String })
  note: string | null;

  @ApiProperty()
  createdAt: Date;

  @ApiProperty()
  updatedAt: Date;
}
