import { Global, Module } from '@nestjs/common';
import { OtpService } from './otp.service';

/**
 * OtpService 依赖全局 REDIS provider（RedisModule 已 @Global 注册）。
 * 限流参数用默认值；要覆盖时在这里 provide OTP_LIMITS。
 */
@Global()
@Module({
  providers: [OtpService],
  exports: [OtpService],
})
export class OtpModule {}
