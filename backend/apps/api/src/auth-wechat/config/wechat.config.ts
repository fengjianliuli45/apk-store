import { registerAs } from '@nestjs/config';
import { IsIn, IsOptional, IsString } from 'class-validator';
import validateConfig from '../../utils/validate-config';
import { WechatConfig, WechatDriverName } from './wechat-config.type';

class EnvironmentVariablesValidator {
  @IsOptional()
  @IsIn(['mock', 'http'])
  WECHAT_DRIVER: WechatDriverName;

  @IsOptional()
  @IsString()
  WECHAT_APP_ID: string;

  @IsOptional()
  @IsString()
  WECHAT_APP_SECRET: string;
}

export default registerAs<WechatConfig>('wechat', () => {
  validateConfig(process.env, EnvironmentVariablesValidator);

  return {
    driver: (process.env.WECHAT_DRIVER as WechatDriverName) || 'mock',
    appId: process.env.WECHAT_APP_ID,
    appSecret: process.env.WECHAT_APP_SECRET,
  };
});
