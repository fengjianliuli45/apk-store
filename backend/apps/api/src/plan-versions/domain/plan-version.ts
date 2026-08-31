import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

/**
 * 一份计划的一个不可变快照。新调整 = 追加一条新 version，绝不覆盖旧的
 * （ADAPTATION_PLAN §4 / §9.2）。
 */
export class PlanVersion {
  @ApiProperty({ type: String })
  id: string;

  @ApiProperty({ type: String })
  planId: string;

  @ApiProperty({ type: Number, example: 1 })
  versionNumber: number;

  @ApiProperty({ type: String, example: '1.8' })
  plannerVersion: string;

  @ApiProperty({ type: String, example: 'dart', description: 'dart | python' })
  generatedBy: string;

  @ApiProperty({
    type: 'object',
    additionalProperties: true,
    description: '问卷原始输入快照（用于日后复现）',
  })
  inputSnapshot: Record<string, unknown>;

  @ApiProperty({
    type: 'object',
    additionalProperties: true,
    description: '引擎产出的完整计划 JSON',
  })
  planJson: Record<string, unknown>;

  @ApiPropertyOptional({ type: String, example: 'check-in: advance' })
  changeReason: string | null;

  @ApiProperty()
  createdAt: Date;
}
