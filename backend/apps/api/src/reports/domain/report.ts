import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export type ReportTargetType = 'post' | 'comment' | 'user';
export type ReportStatus = 'open' | 'reviewing' | 'resolved' | 'dismissed';

export class Report {
  @ApiProperty({ type: String })
  id: string;

  @ApiProperty({ type: Number })
  reporterId: number;

  @ApiProperty({ type: String, example: 'post' })
  targetType: ReportTargetType;

  @ApiProperty({ type: String })
  targetId: string;

  @ApiProperty({ type: String, example: 'spam' })
  reason: string;

  @ApiPropertyOptional({ type: String })
  detail: string | null;

  @ApiProperty({ type: String, example: 'open' })
  status: ReportStatus;

  @ApiProperty()
  createdAt: Date;
}
