import { AppConfig } from './app-config.type';
import { AppleConfig } from '../auth-apple/config/apple-config.type';
import { AuthConfig } from '../auth/config/auth-config.type';
import { DatabaseConfig } from '../database/config/database-config.type';
import { FileConfig } from '../files/config/file-config.type';
import { GoogleConfig } from '../auth-google/config/google-config.type';
import { MailConfig } from '../mail/config/mail-config.type';
import { RedisConfig } from '../redis/config/redis-config.type';
import { SmsConfig } from '../common/sms/config/sms-config.type';
import { AuthPhoneConfig } from '../auth-phone/config/auth-phone-config.type';
import { WechatConfig } from '../auth-wechat/config/wechat-config.type';
import { MediaConfig } from '../media-objects/config/media-config.type';

export type AllConfigType = {
  app: AppConfig;
  apple: AppleConfig;
  auth: AuthConfig;
  database: DatabaseConfig;
  file: FileConfig;
  google: GoogleConfig;
  mail: MailConfig;
  redis: RedisConfig;
  sms: SmsConfig;
  authPhone: AuthPhoneConfig;
  wechat: WechatConfig;
  media: MediaConfig;
};
