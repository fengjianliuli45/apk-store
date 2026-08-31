import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  ArrayMaxSize,
  IsArray,
  IsIn,
  IsOptional,
  IsString,
  MaxLength,
  ValidateIf,
} from 'class-validator';

const KINDS = ['text', 'workout', 'plan', 'progress'];
const VISIBILITY = ['public', 'followers'];
const REF_TYPES = ['workout_session', 'plan_version'];

export class CreatePostDto {
  @ApiProperty({ enum: KINDS, default: 'text' })
  @IsOptional()
  @IsIn(KINDS)
  kind?: string;

  @ApiProperty({ example: '今天练腿，PR 了' })
  @IsString()
  @MaxLength(5000)
  body: string;

  @ApiPropertyOptional({
    type: [String],
    description: 'media_object id（先传完 complete）',
  })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(9)
  @IsString({ each: true })
  mediaIds?: string[];

  @ApiPropertyOptional({ enum: REF_TYPES })
  @IsOptional()
  @IsIn(REF_TYPES)
  refType?: string;

  @ApiPropertyOptional()
  @ValidateIf((o) => o.refType !== undefined)
  @IsString()
  @MaxLength(64)
  refId?: string;

  @ApiPropertyOptional({ enum: VISIBILITY, default: 'public' })
  @IsOptional()
  @IsIn(VISIBILITY)
  visibility?: string;
}
