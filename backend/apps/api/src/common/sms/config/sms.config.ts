import { registerAs } from '@nestjs/config';
import { IsIn, IsOptional, IsString } from 'class-validator';
import validateConfig from '../../../utils/validate-config';
import { SmsConfig, SmsDriver } from './sms-config.type';

class EnvironmentVariablesValidator {
  @IsOptional()
  @IsIn(['console', 'aliyun', 'tencent'])
  SMS_DRIVER: SmsDriver;

  @IsOptional()
  @IsString()
  SMS_ALIYUN_ACCESS_KEY_ID: string;

  @IsOptional()
  @IsString()
  SMS_ALIYUN_ACCESS_KEY_SECRET: string;

  @IsOptional()
  @IsString()
  SMS_TENCENT_SECRET_ID: string;

  @IsOptional()
  @IsString()
  SMS_TENCENT_SECRET_KEY: string;
}

export default registerAs<SmsConfig>('sms', () => {
  validateConfig(process.env, EnvironmentVariablesValidator);

  return {
    driver: (process.env.SMS_DRIVER as SmsDriver) || 'console',
    aliyunAccessKeyId: process.env.SMS_ALIYUN_ACCESS_KEY_ID,
    aliyunAccessKeySecret: process.env.SMS_ALIYUN_ACCESS_KEY_SECRET,
    aliyunSignName: process.env.SMS_ALIYUN_SIGN_NAME,
    aliyunTemplateCode: process.env.SMS_ALIYUN_TEMPLATE_CODE,
    tencentSecretId: process.env.SMS_TENCENT_SECRET_ID,
    tencentSecretKey: process.env.SMS_TENCENT_SECRET_KEY,
    tencentSdkAppId: process.env.SMS_TENCENT_SDK_APP_ID,
    tencentSignName: process.env.SMS_TENCENT_SIGN_NAME,
    tencentTemplateId: process.env.SMS_TENCENT_TEMPLATE_ID,
  };
});
