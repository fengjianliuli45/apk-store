import { Injectable, Logger } from '@nestjs/common';

/**
 * 短信发送抽象。真实渠道（阿里云 / 腾讯云 SMS）等接密钥时再加 driver；
 * 开发 / 测试用 console driver，把验证码打到日志。
 */
export abstract class SmsService {
  abstract sendVerificationCode(phone: string, code: string): Promise<void>;
}

@Injectable()
export class ConsoleSmsService extends SmsService {
  private readonly logger = new Logger('SmsService');

  async sendVerificationCode(phone: string, code: string): Promise<void> {
    this.logger.log(`[console-sms] -> ${phone} 验证码: ${code}`);
    return Promise.resolve();
  }
}
