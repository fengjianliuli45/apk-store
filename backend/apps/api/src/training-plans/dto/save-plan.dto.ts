import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsIn,
  IsNotEmptyObject,
  IsObject,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';

/**
 * 客户端把本地（Dart 引擎）生成的计划回传保存。
 * 服务端不重新生成计划——只存快照 + 版本化（ADAPTATION_PLAN §9.2）。
 */
export class SavePlanDto {
  @ApiProperty({ example: '1.8' })
  @IsString()
  @MaxLength(16)
  plannerVersion: string;

  @ApiProperty({ example: 'dart', enum: ['dart', 'python'] })
  @IsIn(['dart', 'python'])
  generatedBy: string;

  @ApiProperty({
    type: 'object',
    additionalProperties: true,
    description: '问卷原始输入（复现用）',
  })
  @IsObject()
  @IsNotEmptyObject()
  inputSnapshot: Record<string, unknown>;

  @ApiProperty({
    type: 'object',
    additionalProperties: true,
    description: '引擎产出的完整计划 JSON',
  })
  @IsObject()
  @IsNotEmptyObject()
  planJson: Record<string, unknown>;

  @ApiPropertyOptional({ example: 'check-in: advance' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  changeReason?: string;
}
