export type SmsDriver = 'console' | 'aliyun' | 'tencent';

export type SmsConfig = {
  driver: SmsDriver;
  aliyunAccessKeyId?: string;
  aliyunAccessKeySecret?: string;
  aliyunSignName?: string;
  aliyunTemplateCode?: string;
  tencentSecretId?: string;
  tencentSecretKey?: string;
  tencentSdkAppId?: string;
  tencentSignName?: string;
  tencentTemplateId?: string;
};
