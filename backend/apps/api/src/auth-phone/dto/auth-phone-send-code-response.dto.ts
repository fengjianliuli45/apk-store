import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class AuthPhoneSendCodeResponseDto {
  @ApiProperty({ example: 300, description: '验证码有效期（秒）' })
  expiresIn: number;

  @ApiPropertyOptional({
    example: '123456',
    description: '仅当 AUTH_PHONE_EXPOSE_CODE=true（开发环境）时返回',
  })
  code?: string;
}
