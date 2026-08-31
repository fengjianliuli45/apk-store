import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsBoolean,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';

export class WorkoutSetInputDto {
  @ApiProperty({ example: 'horizontal_push' })
  @IsString()
  @MaxLength(80)
  exerciseKey: string;

  @ApiProperty({ example: '杠铃卧推' })
  @IsString()
  @MaxLength(120)
  exerciseName: string;

  @ApiProperty({ example: 1 })
  @IsInt()
  @Min(0)
  @Max(100)
  setIndex: number;

  @ApiPropertyOptional({ example: 8 })
  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(1000)
  reps?: number;

  @ApiPropertyOptional({ example: 60 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(2000)
  weightKg?: number;

  @ApiPropertyOptional({ example: 2 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(10)
  rir?: number;

  @ApiPropertyOptional({ default: false })
  @IsOptional()
  @IsBoolean()
  isWarmup?: boolean;
}

export class AddSetsDto {
  @ApiProperty({ type: [WorkoutSetInputDto] })
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(200)
  @ValidateNested({ each: true })
  @Type(() => WorkoutSetInputDto)
  sets: WorkoutSetInputDto[];
}
