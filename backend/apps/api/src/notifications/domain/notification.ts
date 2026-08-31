import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

/** 站内通知一条。type 决定客户端图标 / 跳转；data 带 deep-link 参数。 */
export class Notification {
  @ApiProperty({ type: String })
  id: string;

  @ApiProperty({ type: Number })
  userId: number;

  @ApiProperty({ type: String, example: 'workout_reminder' })
  type: string;

  @ApiProperty({ type: String })
  title: string;

  @ApiProperty({ type: String })
  body: string;

  @ApiProperty({ type: 'object', additionalProperties: true })
  data: Record<string, unknown>;

  @ApiPropertyOptional({ type: Date })
  readAt: Date | null;

  @ApiProperty()
  createdAt: Date;
}
