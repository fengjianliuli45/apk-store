import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export type PostVisibility = 'public' | 'followers';

export class SocialPost {
  @ApiProperty({ type: String })
  id: string;

  @ApiProperty({ type: Number })
  authorId: number;

  @ApiProperty({ type: String, example: 'text' })
  kind: string;

  @ApiProperty({ type: String })
  body: string;

  @ApiProperty({ type: [String], description: 'media_object id 列表' })
  mediaIds: string[];

  @ApiPropertyOptional({
    type: String,
    example: 'workout_session',
    description: '分享的训练 / 计划：workout_session | plan_version',
  })
  refType: string | null;

  @ApiPropertyOptional({ type: String })
  refId: string | null;

  @ApiProperty({ type: String, example: 'public' })
  visibility: PostVisibility;

  @ApiProperty({ type: Number })
  likeCount: number;

  @ApiProperty({ type: Number })
  commentCount: number;

  @ApiProperty({ type: String, example: 'pending' })
  moderationStatus: string;

  @ApiProperty()
  createdAt: Date;

  @ApiPropertyOptional({
    type: Date,
    description: '软删除（tombstone，同步要）',
  })
  deletedAt: Date | null;
}
