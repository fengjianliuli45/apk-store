import { registerAs } from '@nestjs/config';
import { IsBooleanString, IsOptional } from 'class-validator';
import validateConfig from '../../utils/validate-config';
import { AuthPhoneConfig } from './auth-phone-config.type';

class EnvironmentVariablesValidator {
  @IsOptional()
  @IsBooleanString()
  AUTH_PHONE_EXPOSE_CODE: string;
}

export default registerAs<AuthPhoneConfig>('authPhone', () => {
  validateConfig(process.env, EnvironmentVariablesValidator);

  return {
    exposeCode: process.env.AUTH_PHONE_EXPOSE_CODE === 'true',
  };
});
