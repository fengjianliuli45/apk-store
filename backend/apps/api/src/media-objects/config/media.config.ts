import { registerAs } from '@nestjs/config';
import { IsIn, IsOptional, IsString } from 'class-validator';
import validateConfig from '../../utils/validate-config';
import { MediaConfig, MediaDriver } from './media-config.type';

class EnvironmentVariablesValidator {
  @IsOptional()
  @IsIn(['fake', 's3'])
  MEDIA_DRIVER: MediaDriver;

  @IsOptional()
  @IsString()
  MEDIA_S3_ENDPOINT: string;

  @IsOptional()
  @IsString()
  MEDIA_S3_BUCKET: string;
}

export default registerAs<MediaConfig>('media', () => {
  validateConfig(process.env, EnvironmentVariablesValidator);

  return {
    driver: (process.env.MEDIA_DRIVER as MediaDriver) || 'fake',
    s3Endpoint: process.env.MEDIA_S3_ENDPOINT,
    s3Region: process.env.MEDIA_S3_REGION,
    s3Bucket: process.env.MEDIA_S3_BUCKET,
    s3AccessKeyId: process.env.MEDIA_S3_ACCESS_KEY_ID,
    s3SecretAccessKey: process.env.MEDIA_S3_SECRET_ACCESS_KEY,
    s3ForcePathStyle: process.env.MEDIA_S3_FORCE_PATH_STYLE === 'true',
    publicBaseUrl: process.env.MEDIA_PUBLIC_BASE_URL,
    uploadUrlTtlSeconds: process.env.MEDIA_UPLOAD_URL_TTL
      ? parseInt(process.env.MEDIA_UPLOAD_URL_TTL, 10)
      : 300,
    readUrlTtlSeconds: process.env.MEDIA_READ_URL_TTL
      ? parseInt(process.env.MEDIA_READ_URL_TTL, 10)
      : 3600,
  };
});
