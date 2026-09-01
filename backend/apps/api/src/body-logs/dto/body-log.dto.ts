import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsInt,
  IsISO8601,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

export class UpsertBodyLogDto {
  @ApiProperty({ example: '2026-09-01', description: 'ISO date' })
  @IsISO8601()
  measuredOn: string;

  @ApiPropertyOptional({ example: 72.4 })
  @IsOptional()
  @IsNumber()
  @Min(20)
  @Max(400)
  weightKg?: number;

  @ApiPropertyOptional({ example: 18.2 })
  @IsOptional()
  @IsNumber()
  @Min(2)
  @Max(70)
  bodyFatPct?: number;

  @ApiPropertyOptional({ example: 80 })
  @IsOptional()
  @IsNumber()
  @Min(30)
  @Max(250)
  waistCm?: number;

  @ApiPropertyOptional({ example: 40 })
  @IsOptional()
  @IsNumber()
  @Min(15)
  @Max(100)
  armCm?: number;

  @ApiPropertyOptional({ example: 58 })
  @IsOptional()
  @IsNumber()
  @Min(20)
  @Max(120)
  thighCm?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(500)
  note?: string;
}

export class ListBodyLogsQueryDto {
  @ApiPropertyOptional({ default: 60, maximum: 200 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(200)
  limit?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  cursor?: string;

  @ApiPropertyOptional({ description: 'measuredOn >= from（ISO date）' })
  @IsOptional()
  @IsISO8601()
  from?: string;

  @ApiPropertyOptional({ description: 'measuredOn <= to（ISO date）' })
  @IsOptional()
  @IsISO8601()
  to?: string;
}
