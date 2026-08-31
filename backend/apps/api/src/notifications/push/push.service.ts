import { Injectable, Logger } from '@nestjs/common';

export type PushTarget = {
  platform: string;
  token: string;
  vendorChannel: string | null;
};

export type PushMessage = {
  title: string;
  body: string;
  data: Record<string, unknown>;
};

export type PushResult = { ok: boolean; error?: string };

/**
 * 推送发送抽象。真实通道按 target.platform 分发（ADAPTATION_PLAN §9.4）：
 *   ios          → APNs
 *   android_fcm  → FCM（国际）
 *   android_vendor → 厂商 / 聚合（小米 / 华为 / OPPO / vivo / 个推 / 极光），看 vendorChannel
 * 现在只有 console 实现；接密钥时在这里加。
 */
export abstract class PushService {
  abstract send(target: PushTarget, message: PushMessage): Promise<PushResult>;
}

@Injectable()
export class ConsolePushService extends PushService {
  private readonly logger = new Logger('PushService');

  send(target: PushTarget, message: PushMessage): Promise<PushResult> {
    this.logger.log(
      `[console-push] ${target.platform}` +
        `${target.vendorChannel ? `/${target.vendorChannel}` : ''} ` +
        `token=${target.token.slice(0, 8)}… "${message.title}"`,
    );
    return Promise.resolve({ ok: true });
  }
}

@Injectable()
export class OffPushService extends PushService {
  send(): Promise<PushResult> {
    return Promise.resolve({ ok: false, error: 'pushDisabled' });
  }
}
