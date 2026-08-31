import {
  Body,
  Controller,
  HttpCode,
  HttpStatus,
  Post,
  SerializeOptions,
} from '@nestjs/common';
import { ApiOkResponse, ApiTags } from '@nestjs/swagger';
import { AuthService } from '../auth/auth.service';
import { AuthProvidersEnum } from '../auth/auth-providers.enum';
import { LoginResponseDto } from '../auth/dto/login-response.dto';
import { AuthWechatService } from './auth-wechat.service';
import { AuthWechatLoginDto } from './dto/auth-wechat-login.dto';

@ApiTags('Auth')
@Controller({
  path: 'auth/wechat',
  version: '1',
})
export class AuthWechatController {
  constructor(
    private readonly authService: AuthService,
    private readonly authWechatService: AuthWechatService,
  ) {}

  @ApiOkResponse({ type: LoginResponseDto })
  @SerializeOptions({ groups: ['me'] })
  @Post('login')
  @HttpCode(HttpStatus.OK)
  async login(@Body() dto: AuthWechatLoginDto): Promise<LoginResponseDto> {
    const providerUid = await this.authWechatService.resolveProviderUid(
      dto.code,
    );
    return this.authService.validateIdentityLogin(
      AuthProvidersEnum.wechat,
      providerUid,
    );
  }
}
