import { ApiProperty } from '@nestjs/swagger';

export class UserIdentity {
  @ApiProperty({ type: String })
  id: string;

  @ApiProperty({ type: String, example: 'phone' })
  provider: string;

  @ApiProperty({ type: String, example: '+8613800000000' })
  providerUid: string;

  @ApiProperty({ type: Number })
  userId: number;

  @ApiProperty()
  createdAt: Date;

  @ApiProperty()
  updatedAt: Date;
}
