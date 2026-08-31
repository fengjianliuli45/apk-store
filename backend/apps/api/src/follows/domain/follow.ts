import { ApiProperty } from '@nestjs/swagger';

export class Follow {
  @ApiProperty({ type: String })
  id: string;

  @ApiProperty({ type: Number })
  followerId: number;

  @ApiProperty({ type: Number })
  followeeId: number;

  @ApiProperty()
  createdAt: Date;
}
