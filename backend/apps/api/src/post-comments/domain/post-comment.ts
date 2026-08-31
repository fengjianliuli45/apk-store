import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class PostComment {
  @ApiProperty({ type: String })
  id: string;

  @ApiProperty({ type: String })
  postId: string;

  @ApiProperty({ type: Number })
  authorId: number;

  @ApiProperty({ type: String })
  body: string;

  @ApiProperty({ type: String, example: 'pending' })
  moderationStatus: string;

  @ApiProperty()
  createdAt: Date;

  @ApiPropertyOptional({ type: Date })
  deletedAt: Date | null;
}
