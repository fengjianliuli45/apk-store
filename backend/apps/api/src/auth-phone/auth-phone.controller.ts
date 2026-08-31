import {
  Body,
  Controller,
  HttpCode,
  HttpStatus,
  Ip,
  Post,
  SerializeOptions,
} from '@nestjs/common';
import { ApiOkResponse, ApiTags } from '@nestjs/swagger';
import { AuthService } from '../auth/auth.service';
import { AuthProvidersEnum } from '../auth/auth-providers.enum';
import { LoginResponseDto } from '../auth/dto/login-response.dto';
import { AuthPhoneService } from './auth-phone.service';
import { AuthPhoneSendCodeDto } from './dto/auth-phone-send-code.dto';
import { AuthPhoneLoginDto } from './dto/auth-phone-login.dto';
import { AuthPhoneSendCodeResponseDto } from './dto/auth-phone-send-code-response.dto';

@ApiTags('Auth')
@Controller({
  path: 'auth/phone',
  version: '1',
})
export class AuthPhoneController {
  constructor(
    private readonly authService: AuthService,
    private readonly authPhoneService: AuthPhoneService,
  ) {}

  @ApiOkResponse({ type: AuthPhoneSendCodeResponseDto })
  @Post('send-code')
  @HttpCode(HttpStatus.OK)
  sendCode(
    @Body() dto: AuthPhoneSendCodeDto,
    @Ip() ip: string,
  ): Promise<AuthPhoneSendCodeResponseDto> {
    return this.authPhoneService.sendCode(dto.phone, ip);
  }

  @ApiOkResponse({ type: LoginResponseDto })
  @SerializeOptions({ groups: ['me'] })
  @Post('login')
  @HttpCode(HttpStatus.OK)
  async login(@Body() dto: AuthPhoneLoginDto): Promise<LoginResponseDto> {
    const phone = await this.authPhoneService.verifyCode(dto.phone, dto.code);
    return this.authService.validateIdentityLogin(
      AuthProvidersEnum.phone,
      phone,
    );
  }
}
