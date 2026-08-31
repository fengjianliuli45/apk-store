import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

export class CursorQueryDto {
  @ApiPropertyOptional({ default: 20, maximum: 50 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(50)
  limit?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  cursor?: string;
}

export class AddCommentDto {
  @ApiProperty({ example: '牛' })
  @IsString()
  @MaxLength(2000)
  body: string;
}

const REPORT_TARGETS = ['post', 'comment', 'user'];
const REPORT_REASONS = [
  'spam',
  'harassment',
  'nudity',
  'violence',
  'hate',
  'illegal',
  'other',
];

export class CreateReportDto {
  @ApiProperty({ enum: REPORT_TARGETS })
  @IsIn(REPORT_TARGETS)
  targetType: string;

  @ApiProperty()
  @IsString()
  @MaxLength(64)
  targetId: string;

  @ApiProperty({ enum: REPORT_REASONS })
  @IsIn(REPORT_REASONS)
  reason: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  detail?: string;
}
