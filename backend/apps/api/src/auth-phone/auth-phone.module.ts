import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AuthModule } from '../auth/auth.module';
import { OtpModule } from '../common/otp/otp.module';
import { SmsModule } from '../common/sms/sms.module';
import { AuthPhoneController } from './auth-phone.controller';
import { AuthPhoneService } from './auth-phone.service';

@Module({
  imports: [ConfigModule, AuthModule, OtpModule, SmsModule],
  controllers: [AuthPhoneController],
  providers: [AuthPhoneService],
  exports: [AuthPhoneService],
})
export class AuthPhoneModule {}
