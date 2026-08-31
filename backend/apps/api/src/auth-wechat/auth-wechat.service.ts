import { Injectable } from '@nestjs/common';
import { WechatDriver } from './wechat.driver';

@Injectable()
export class AuthWechatService {
  constructor(private readonly wechatDriver: WechatDriver) {}

  /**
   * code -> 稳定用户键。优先用 unionid（跨微信应用一致），没有则退回 openid。
   * 这个键就是 user_identities 的 providerUid。
   */
  async resolveProviderUid(code: string): Promise<string> {
    const session = await this.wechatDriver.code2Session(code);
    return session.unionid ?? session.openid;
  }
}
