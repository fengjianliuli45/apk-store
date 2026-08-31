import { registerAs } from '@nestjs/config';
import { IsString } from 'class-validator';
import validateConfig from '../../utils/validate-config';
import { RedisConfig } from './redis-config.type';

class EnvironmentVariablesValidator {
  @IsString()
  REDIS_URL: string;
}

export default registerAs<RedisConfig>('redis', () => {
  validateConfig(process.env, EnvironmentVariablesValidator);
  return {
    url: process.env.REDIS_URL || 'redis://localhost:6379',
  };
});
