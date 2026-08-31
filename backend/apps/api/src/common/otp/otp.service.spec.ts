import { UnprocessableEntityException } from '@nestjs/common';
import { OtpRedis, OtpService } from './otp.service';

/** 内存假 Redis：够覆盖 OtpService 用到的命令 + TTL 语义。 */
class FakeRedis implements OtpRedis {
  private store = new Map<string, { value: string; expireAt: number | null }>();
  now = 1_700_000_000_000;

  private live(key: string) {
    const e = this.store.get(key);
    if (!e) return undefined;
    if (e.expireAt !== null && e.expireAt <= this.now) {
      this.store.delete(key);
      return undefined;
    }
    return e;
  }

  get(key: string): Promise<string | null> {
    return Promise.resolve(this.live(key)?.value ?? null);
  }

  set(
    key: string,
    value: string,
    _exFlag: 'EX',
    seconds: number,
    nxFlag?: 'NX',
  ): Promise<unknown> {
    if (nxFlag === 'NX' && this.live(key)) return Promise.resolve(null);
    this.store.set(key, { value, expireAt: this.now + seconds * 1000 });
    return Promise.resolve('OK');
  }

  del(key: string): Promise<unknown> {
    this.store.delete(key);
    return Promise.resolve(1);
  }

  incr(key: string): Promise<number> {
    const cur = this.live(key);
    const next = (cur ? parseInt(cur.value, 10) : 0) + 1;
    this.store.set(key, {
      value: String(next),
      expireAt: cur ? cur.expireAt : null,
    });
    return Promise.resolve(next);
  }

  expire(key: string, seconds: number): Promise<unknown> {
    const e = this.store.get(key);
    if (e) e.expireAt = this.now + seconds * 1000;
    return Promise.resolve(1);
  }

  ttl(key: string): Promise<number> {
    const e = this.live(key);
    if (!e) return Promise.resolve(-2);
    if (e.expireAt === null) return Promise.resolve(-1);
    return Promise.resolve(Math.ceil((e.expireAt - this.now) / 1000));
  }
}

describe('OtpService', () => {
  let redis: FakeRedis;
  let otp: OtpService;

  beforeEach(() => {
    redis = new FakeRedis();
    otp = new OtpService(redis, {
      resendCooldownSeconds: 60,
      perKeyDailyMax: 3,
      perIpHourlyMax: 5,
      maxVerifyAttempts: 3,
      codeTtlSeconds: 300,
    });
  });

  it('should issue a code of the configured length then verifies it', async () => {
    const code = await otp.issue('s', '+8613800000000', '1.1.1.1');
    expect(code).toMatch(/^\d{6}$/);
    await expect(
      otp.verify('s', '+8613800000000', code),
    ).resolves.toBeUndefined();
  });

  it('should consume the code on success (second verify fails)', async () => {
    const code = await otp.issue('s', 'k', 'ip');
    await otp.verify('s', 'k', code);
    await expect(otp.verify('s', 'k', code)).rejects.toBeInstanceOf(
      UnprocessableEntityException,
    );
  });

  it('should reject a resend within the cooldown window', async () => {
    await otp.issue('s', 'k', 'ip');
    await expect(otp.issue('s', 'k', 'ip')).rejects.toBeInstanceOf(
      UnprocessableEntityException,
    );
    redis.now += 61_000;
    await expect(otp.issue('s', 'k', 'ip')).resolves.toMatch(/^\d{6}$/);
  });

  it('should enforce the per-key daily cap', async () => {
    for (let i = 0; i < 3; i++) {
      await otp.issue('s', 'k', 'ip');
      redis.now += 61_000;
    }
    await expect(otp.issue('s', 'k', 'ip')).rejects.toBeInstanceOf(
      UnprocessableEntityException,
    );
  });

  it('should invalidate the code after too many wrong attempts', async () => {
    const code = await otp.issue('s', 'k', 'ip');
    const wrong = code === '000000' ? '111111' : '000000';
    await expect(otp.verify('s', 'k', wrong)).rejects.toThrow();
    await expect(otp.verify('s', 'k', wrong)).rejects.toThrow();
    // third wrong attempt hits the cap and clears the code
    await expect(otp.verify('s', 'k', wrong)).rejects.toThrow();
    // even the correct code no longer works
    await expect(otp.verify('s', 'k', code)).rejects.toBeInstanceOf(
      UnprocessableEntityException,
    );
  });

  it('should scope limits independently per scope', async () => {
    await otp.issue('login', 'k', 'ip');
    await expect(otp.issue('bind', 'k', 'ip')).resolves.toMatch(/^\d{6}$/);
  });
});
