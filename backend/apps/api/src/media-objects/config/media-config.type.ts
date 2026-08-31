export type MediaDriver = 'fake' | 's3';

export type MediaConfig = {
  driver: MediaDriver;
  s3Endpoint?: string;
  s3Region?: string;
  s3Bucket?: string;
  s3AccessKeyId?: string;
  s3SecretAccessKey?: string;
  s3ForcePathStyle: boolean;
  /** CDN / OSS 公网读地址前缀；设了就用它拼读 URL，不走预签名 GET */
  publicBaseUrl?: string;
  uploadUrlTtlSeconds: number;
  readUrlTtlSeconds: number;
};
