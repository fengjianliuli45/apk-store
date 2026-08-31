import { ApiProperty } from '@nestjs/swagger';

export class PostLike {
  @ApiProperty({ type: String })
  id: string;

  @ApiProperty({ type: String })
  postId: string;

  @ApiProperty({ type: Number })
  userId: number;

  @ApiProperty()
  createdAt: Date;
}
