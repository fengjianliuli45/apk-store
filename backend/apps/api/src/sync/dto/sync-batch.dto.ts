import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsIn,
  IsISO8601,
  IsObject,
  IsOptional,
  IsString,
  MaxLength,
  ValidateNested,
} from 'class-validator';

const ENTITY_TYPES = ['workout_session', 'workout_set', 'profile', 'body_log'];
const OPS = ['create', 'update', 'delete'];

export class SyncEventInputDto {
  @ApiProperty({ description: '客户端生成的幂等键（如 UUID）' })
  @IsString()
  @MaxLength(64)
  clientEventId: string;

  @ApiProperty({ enum: ENTITY_TYPES })
  @IsIn(ENTITY_TYPES)
  entityType: string;

  @ApiProperty({ enum: OPS })
  @IsIn(OPS)
  op: string;

  @ApiProperty({ type: 'object', additionalProperties: true })
  @IsObject()
  payload: Record<string, unknown>;

  @ApiPropertyOptional({ description: '客户端记录该变更的时间（ISO）' })
  @IsOptional()
  @IsISO8601()
  occurredAt?: string;
}

export class SyncBatchDto {
  @ApiProperty({ type: [SyncEventInputDto] })
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(500)
  @ValidateNested({ each: true })
  @Type(() => SyncEventInputDto)
  events: SyncEventInputDto[];
}
