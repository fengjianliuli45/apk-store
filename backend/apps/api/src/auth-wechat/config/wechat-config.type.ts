export type WechatDriverName = 'mock' | 'http';

export type WechatConfig = {
  driver: WechatDriverName;
  appId?: string;
  appSecret?: string;
};
