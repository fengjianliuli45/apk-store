import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString } from 'class-validator';

export class AuthPhoneSendCodeDto {
  @ApiProperty({ example: '13800000000' })
  @IsString()
  @IsNotEmpty()
  phone: string;
}
