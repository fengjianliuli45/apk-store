import { Global, Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AllConfigType } from '../../config/config.type';
import { ConsoleSmsService, SmsService } from './sms.service';

/**
 * SMS driver 由 `SMS_DRIVER` 决定。目前只实现 console；
 * aliyun / tencent 接密钥时在这里加 useClass 分支。
 */
@Global()
@Module({
  providers: [
    {
      provide: SmsService,
      inject: [ConfigService],
      useFactory: (config: ConfigService<AllConfigType>) => {
        const driver = config.get('sms.driver', { infer: true });
        switch (driver) {
          case 'console':
          default:
            return new ConsoleSmsService();
        }
      },
    },
  ],
  exports: [SmsService],
})
export class SmsModule {}
