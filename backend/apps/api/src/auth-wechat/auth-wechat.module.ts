import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { AuthModule } from '../auth/auth.module';
import { AllConfigType } from '../config/config.type';
import { AuthWechatController } from './auth-wechat.controller';
import { AuthWechatService } from './auth-wechat.service';
import {
  HttpWechatDriver,
  MockWechatDriver,
  WechatDriver,
} from './wechat.driver';

@Module({
  imports: [ConfigModule, AuthModule],
  controllers: [AuthWechatController],
  providers: [
    AuthWechatService,
    {
      provide: WechatDriver,
      inject: [ConfigService],
      useFactory: (config: ConfigService<AllConfigType>) => {
        const driver = config.get('wechat.driver', { infer: true });
        return driver === 'http'
          ? new HttpWechatDriver(config)
          : new MockWechatDriver();
      },
    },
  ],
  exports: [AuthWechatService],
})
export class AuthWechatModule {}
