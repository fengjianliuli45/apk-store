import {
  HttpStatus,
  Injectable,
  Logger,
  UnprocessableEntityException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AllConfigType } from '../config/config.type';

export type WechatSession = {
  openid: string;
  unionid?: string;
};

/**
 * 微信 code -> 会话。App 端拿 `code`，服务端换 openid / unionid。
 * `unionid` 是跨应用的稳定用户标识，用它关联账号（ADAPTATION_PLAN §3）。
 */
export abstract class WechatDriver {
  abstract code2Session(code: string): Promise<WechatSession>;
}

/** 开发 / 测试用：不打微信接口，按 code 造一个稳定的 openid/unionid。 */
@Injectable()
export class MockWechatDriver extends WechatDriver {
  code2Session(code: string): Promise<WechatSession> {
    return Promise.resolve({
      openid: `mock-openid-${code}`,
      unionid: `mock-unionid-${code}`,
    });
  }
}

@Injectable()
export class HttpWechatDriver extends WechatDriver {
  private readonly logger = new Logger('WechatDriver');

  constructor(private readonly configService: ConfigService<AllConfigType>) {
    super();
  }

  async code2Session(code: string): Promise<WechatSession> {
    const appId = this.configService.get('wechat.appId', { infer: true });
    const appSecret = this.configService.get('wechat.appSecret', {
      infer: true,
    });

    if (!appId || !appSecret) {
      throw new UnprocessableEntityException({
        status: HttpStatus.UNPROCESSABLE_ENTITY,
        errors: { wechat: 'notConfigured' },
      });
    }

    const url = new URL('https://api.weixin.qq.com/sns/oauth2/access_token');
    url.searchParams.set('appid', appId);
    url.searchParams.set('secret', appSecret);
    url.searchParams.set('code', code);
    url.searchParams.set('grant_type', 'authorization_code');

    let payload: {
      openid?: string;
      unionid?: string;
      errcode?: number;
      errmsg?: string;
    };
    try {
      const res = await fetch(url, { method: 'GET' });
      payload = (await res.json()) as typeof payload;
    } catch (error) {
      this.logger.error('code2Session request failed', error as Error);
      throw new UnprocessableEntityException({
        status: HttpStatus.UNPROCESSABLE_ENTITY,
        errors: { wechat: 'upstreamUnavailable' },
      });
    }

    if (payload.errcode || !payload.openid) {
      this.logger.warn(
        `code2Session rejected: ${payload.errcode} ${payload.errmsg ?? ''}`,
      );
      throw new UnprocessableEntityException({
        status: HttpStatus.UNPROCESSABLE_ENTITY,
        errors: { code: 'invalidCode' },
      });
    }

    return { openid: payload.openid, unionid: payload.unionid };
  }
}
