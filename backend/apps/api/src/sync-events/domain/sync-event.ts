import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export type SyncOp = 'create' | 'update' | 'delete';

/**
 * 一条已被服务端接受的领域变更。每用户一条单调递增 `serverSeq`，
 * 客户端按 serverSeq 拉增量。`clientEventId` 用于幂等去重（ADAPTATION_PLAN §9.1）。
 */
export class SyncEvent {
  @ApiProperty({ type: String })
  id: string;

  @ApiProperty({ type: Number })
  userId: number;

  @ApiProperty({ type: Number, example: 42, description: '每用户单调递增' })
  serverSeq: number;

  @ApiProperty({ type: String, example: 'workout_session' })
  entityType: string;

  @ApiPropertyOptional({ type: String })
  entityId: string | null;

  @ApiProperty({ type: String, example: 'create' })
  op: SyncOp;

  @ApiProperty({
    type: 'object',
    additionalProperties: true,
    description: '变更后的实体快照 / 变更内容',
  })
  payload: Record<string, unknown>;

  @ApiPropertyOptional({
    type: String,
    description: '客户端事件 id（幂等键）；服务端自发的事件为 null',
  })
  clientEventId: string | null;

  @ApiProperty()
  occurredAt: Date;

  @ApiProperty()
  createdAt: Date;
}
