import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class BatchItemResultDto {
  @ApiProperty()
  clientEventId: string;

  @ApiProperty({ enum: ['applied', 'duplicate', 'rejected'] })
  status: 'applied' | 'duplicate' | 'rejected';

  @ApiPropertyOptional({ type: Number })
  serverSeq?: number;

  @ApiPropertyOptional({ type: String })
  error?: string;
}

export class BatchResultDto {
  @ApiProperty({ type: BatchItemResultDto, isArray: true })
  results: BatchItemResultDto[];

  @ApiProperty({ type: Number, description: '本用户当前最新 serverSeq' })
  syncCursor: number;
}

export class SyncEventDto {
  @ApiProperty()
  id: string;

  @ApiProperty({ type: Number })
  serverSeq: number;

  @ApiProperty({ example: 'workout_session' })
  entityType: string;

  @ApiPropertyOptional({ type: String })
  entityId: string | null;

  @ApiProperty({ enum: ['create', 'update', 'delete'] })
  op: string;

  @ApiProperty({ type: 'object', additionalProperties: true })
  payload: Record<string, unknown>;

  @ApiPropertyOptional({ type: String })
  clientEventId: string | null;

  @ApiProperty()
  occurredAt: Date;

  @ApiProperty()
  createdAt: Date;
}

export class PullResultDto {
  @ApiProperty({ type: SyncEventDto, isArray: true })
  events: SyncEventDto[];

  @ApiProperty({ type: Number })
  nextCursor: number;

  @ApiProperty({ type: Boolean })
  hasMore: boolean;
}
