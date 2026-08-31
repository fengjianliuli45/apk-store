import {
  HttpStatus,
  Injectable,
  UnprocessableEntityException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AllConfigType } from '../config/config.type';
import { OtpService } from '../common/otp/otp.service';
import { SmsService } from '../common/sms/sms.service';
import { normalizePhone } from './phone.util';

const OTP_SCOPE = 'phone-login';

@Injectable()
export class AuthPhoneService {
  constructor(
    private readonly otpService: OtpService,
    private readonly smsService: SmsService,
    private readonly configService: ConfigService<AllConfigType>,
  ) {}

  private normalizeOrThrow(phone: string): string {
    const normalized = normalizePhone(phone);
    if (!normalized) {
      throw new UnprocessableEntityException({
        status: HttpStatus.UNPROCESSABLE_ENTITY,
        errors: { phone: 'invalidPhone' },
      });
    }
    return normalized;
  }

  async sendCode(
    phone: string,
    ip: string,
  ): Promise<{ expiresIn: number; code?: string }> {
    const normalized = this.normalizeOrThrow(phone);
    const code = await this.otpService.issue(OTP_SCOPE, normalized, ip);
    await this.smsService.sendVerificationCode(normalized, code);

    const exposeCode = this.configService.get('authPhone.exposeCode', {
      infer: true,
    });

    return {
      expiresIn: 300,
      ...(exposeCode ? { code } : {}),
    };
  }

  /** 校验验证码，返回归一化后的手机号（= identity 的 providerUid）。 */
  async verifyCode(phone: string, code: string): Promise<string> {
    const normalized = this.normalizeOrThrow(phone);
    await this.otpService.verify(OTP_SCOPE, normalized, code);
    return normalized;
  }
}
