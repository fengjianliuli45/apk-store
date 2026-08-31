import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString } from 'class-validator';

export class AuthWechatLoginDto {
  @ApiProperty({ example: '081abc...', description: '微信 App 端下发的 code' })
  @IsString()
  @IsNotEmpty()
  code: string;
}
