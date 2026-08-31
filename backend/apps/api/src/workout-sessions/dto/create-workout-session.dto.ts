import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsIn,
  IsInt,
  IsISO8601,
  IsOptional,
  IsString,
  IsUUID,
  Min,
} from 'class-validator';

const STATUSES = ['planned', 'in_progress', 'completed', 'skipped'];

export class CreateWorkoutSessionDto {
  @ApiPropertyOptional({ type: String, format: 'uuid' })
  @IsOptional()
  @IsUUID()
  planVersionId?: string;

  @ApiPropertyOptional({ example: 0 })
  @IsOptional()
  @IsInt()
  @Min(0)
  planDayIndex?: number;

  @ApiProperty({ example: 'strength' })
  @IsString()
  sessionType: string;

  @ApiPropertyOptional({ example: '2026-09-01' })
  @IsOptional()
  @IsISO8601()
  scheduledDate?: string;

  @ApiPropertyOptional({ enum: STATUSES, default: 'in_progress' })
  @IsOptional()
  @IsIn(STATUSES)
  status?: string;
}
