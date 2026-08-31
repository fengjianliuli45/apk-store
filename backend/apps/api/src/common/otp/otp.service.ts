import {
  HttpStatus,
  Inject,
  Injectable,
  Optional,
  UnprocessableEntityException,
} from '@nestjs/common';
import { REDIS } from '../../redis/redis.module';

export const OTP_LIMITS = Symbol('OTP_LIMITS');

/**
 * 短信 OTP：码存 Redis（TTL 5min），带三层限流（ADAPTATION_PLAN §9.7）：
 *  - 同一 key 60s 冷却
 *  - 同一 key 每日上限
 *  - 同一 IP 每小时上限
 * 校验错误累计到上限即作废当前码。
 *
 * 只依赖 Redis 的一小组命令，方便用内存假实现做单测。
 */
export interface OtpRedis {
  get(key: string): Promise<string | null>;
  set(
    key: string,
    value: string,
    exFlag: 'EX',
    seconds: number,
    nxFlag?: 'NX',
  ): Promise<unknown>;
  del(key: string): Promise<unknown>;
  incr(key: string): Promise<number>;
  expire(key: string, seconds: number): Promise<unknown>;
  ttl(key: string): Promise<number>;
}

export type OtpLimits = {
  codeTtlSeconds: number;
  resendCooldownSeconds: number;
  perKeyDailyMax: number;
  perIpHourlyMax: number;
  maxVerifyAttempts: number;
  codeLength: number;
};

export const DEFAULT_OTP_LIMITS: OtpLimits = {
  codeTtlSeconds: 300,
  resendCooldownSeconds: 60,
  perKeyDailyMax: 5,
  perIpHourlyMax: 20,
  maxVerifyAttempts: 5,
  codeLength: 6,
};

function tooMany(field: string, reason: string): UnprocessableEntityException {
  return new UnprocessableEntityException({
    status: HttpStatus.UNPROCESSABLE_ENTITY,
    errors: { [field]: reason },
  });
}

@Injectable()
export class OtpService {
  private readonly limits: OtpLimits;

  constructor(
    @Inject(REDIS) private readonly redis: OtpRedis,
    @Optional() @Inject(OTP_LIMITS) limits?: Partial<OtpLimits>,
  ) {
    this.limits = { ...DEFAULT_OTP_LIMITS, ...limits };
  }

  private codeKey(scope: string, key: string) {
    return `otp:${scope}:code:${key}`;
  }
  private cooldownKey(scope: string, key: string) {
    return `otp:${scope}:cd:${key}`;
  }
  private dailyKey(scope: string, key: string) {
    return `otp:${scope}:day:${key}`;
  }
  private ipKey(scope: string, ip: string) {
    return `otp:${scope}:ip:${ip}`;
  }

  private randomCode(): string {
    const max = 10 ** this.limits.codeLength;
    const n = Math.floor(Math.random() * max);
    return n.toString().padStart(this.limits.codeLength, '0');
  }

  /**
   * 生成并存储验证码，返回明文（交给短信 driver 发送）。
   * 触发任一限流则抛 422。
   */
  async issue(scope: string, key: string, ip: string): Promise<string> {
    const cdTtl = await this.redis.ttl(this.cooldownKey(scope, key));
    if (cdTtl > 0) {
      throw tooMany('code', `tooFrequent:${cdTtl}`);
    }

    const dayCount = await this.redis.incr(this.dailyKey(scope, key));
    if (dayCount === 1) {
      await this.redis.expire(this.dailyKey(scope, key), 86400);
    }
    if (dayCount > this.limits.perKeyDailyMax) {
      throw tooMany('code', 'dailyLimit');
    }

    if (ip) {
      const ipCount = await this.redis.incr(this.ipKey(scope, ip));
      if (ipCount === 1) {
        await this.redis.expire(this.ipKey(scope, ip), 3600);
      }
      if (ipCount > this.limits.perIpHourlyMax) {
        throw tooMany('code', 'ipLimit');
      }
    }

    const code = this.randomCode();
    await this.redis.set(
      this.codeKey(scope, key),
      JSON.stringify({ code, attempts: 0 }),
      'EX',
      this.limits.codeTtlSeconds,
    );
    await this.redis.set(
      this.cooldownKey(scope, key),
      '1',
      'EX',
      this.limits.resendCooldownSeconds,
    );
    return code;
  }

  /** 校验验证码。成功即作废该码；累计错误达到上限也作废。 */
  async verify(scope: string, key: string, code: string): Promise<void> {
    const codeKey = this.codeKey(scope, key);
    const raw = await this.redis.get(codeKey);
    if (!raw) {
      throw tooMany('code', 'expiredOrNotRequested');
    }

    let parsed: { code: string; attempts: number };
    try {
      parsed = JSON.parse(raw) as { code: string; attempts: number };
    } catch {
      await this.redis.del(codeKey);
      throw tooMany('code', 'expiredOrNotRequested');
    }

    if (parsed.code === code) {
      await this.redis.del(codeKey);
      return;
    }

    const attempts = parsed.attempts + 1;
    if (attempts >= this.limits.maxVerifyAttempts) {
      await this.redis.del(codeKey);
      throw tooMany('code', 'tooManyAttempts');
    }

    const remainingTtl = Math.max(1, await this.redis.ttl(codeKey));
    await this.redis.set(
      codeKey,
      JSON.stringify({ code: parsed.code, attempts }),
      'EX',
      remainingTtl,
    );
    throw tooMany('code', 'incorrect');
  }
}
