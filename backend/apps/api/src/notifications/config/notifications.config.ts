import { registerAs } from '@nestjs/config';
import { IsIn, IsOptional } from 'class-validator';
import validateConfig from '../../utils/validate-config';
import { NotificationsConfig, PushDriver } from './notifications-config.type';

class EnvironmentVariablesValidator {
  @IsOptional()
  @IsIn(['console', 'off'])
  NOTIFICATIONS_PUSH_DRIVER: PushDriver;
}

export default registerAs<NotificationsConfig>('notifications', () => {
  validateConfig(process.env, EnvironmentVariablesValidator);
  return {
    pushDriver:
      (process.env.NOTIFICATIONS_PUSH_DRIVER as PushDriver) || 'console',
  };
});
