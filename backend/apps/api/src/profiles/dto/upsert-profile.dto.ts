import { ApiPropertyOptional } from '@nestjs/swagger';
import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsIn,
  IsISO8601,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

const GOALS = ['hypertrophy', 'fat_loss', 'strength', 'recomposition'];
const LEVELS = ['beginner', 'intermediate', 'advanced'];
const COOKING = ['full', 'limited', 'none'];
const SEXES = ['male', 'female'];

/**
 * PUT /api/v1/profile/me 的 body。全部可选（分步问卷，逐字段落库）。
 * 校验只做"格式合理"，业务合法性（如目标+器械组合）交给引擎。
 */
export class UpsertProfileDto {
  @ApiPropertyOptional({ enum: SEXES })
  @IsOptional()
  @IsIn(SEXES)
  sex?: string;

  @ApiPropertyOptional({ example: '1995-06-01', description: 'ISO date' })
  @IsOptional()
  @IsISO8601()
  birthdate?: string;

  @ApiPropertyOptional({ example: 175 })
  @IsOptional()
  @IsNumber()
  @Min(90)
  @Max(250)
  heightCm?: number;

  @ApiPropertyOptional({ enum: GOALS })
  @IsOptional()
  @IsIn(GOALS)
  goal?: string;

  @ApiPropertyOptional({ enum: LEVELS })
  @IsOptional()
  @IsIn(LEVELS)
  experienceLevel?: string;

  @ApiPropertyOptional({ example: 60 })
  @IsOptional()
  @IsInt()
  @Min(15)
  @Max(240)
  minutesPerSession?: number;

  @ApiPropertyOptional({ example: 3 })
  @IsOptional()
  @IsInt()
  @Min(2)
  @Max(8)
  mealsPerDay?: number;

  @ApiPropertyOptional({ enum: COOKING })
  @IsOptional()
  @IsIn(COOKING)
  cookingAccess?: string;

  @ApiPropertyOptional({ example: 72.5 })
  @IsOptional()
  @IsNumber()
  @Min(30)
  @Max(400)
  targetWeightKg?: number;

  @ApiPropertyOptional({ example: '右肩偶尔疼' })
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  injuriesText?: string;

  @ApiPropertyOptional({ type: [String], example: ['dumbbell', 'bench'] })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(40)
  @IsString({ each: true })
  @MaxLength(40, { each: true })
  equipment?: string[];

  @ApiPropertyOptional({ type: [String], example: ['vegetarian'] })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(20)
  @IsString({ each: true })
  @MaxLength(40, { each: true })
  dietaryRestrictions?: string[];

  @ApiPropertyOptional({
    description: '勾选同意收集身体数据；true 时记录同意时间戳',
    example: true,
  })
  @IsOptional()
  @IsBoolean()
  bodyDataConsent?: boolean;

  @ApiPropertyOptional({ example: '2026-01', description: '同意的条款版本' })
  @IsOptional()
  @IsString()
  @MaxLength(32)
  bodyDataConsentVersion?: string;
}
