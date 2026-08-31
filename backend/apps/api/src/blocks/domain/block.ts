import { ApiProperty } from '@nestjs/swagger';

export class Block {
  @ApiProperty({ type: String })
  id: string;

  @ApiProperty({ type: Number })
  blockerId: number;

  @ApiProperty({ type: Number })
  blockedId: number;

  @ApiProperty()
  createdAt: Date;
}
