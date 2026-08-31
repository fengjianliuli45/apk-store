import { AuthWechatService } from './auth-wechat.service';
import { MockWechatDriver, WechatDriver } from './wechat.driver';

describe('AuthWechatService', () => {
  it('should prefer unionid over openid as the provider uid', async () => {
    const service = new AuthWechatService(new MockWechatDriver());
    await expect(service.resolveProviderUid('abc')).resolves.toBe(
      'mock-unionid-abc',
    );
  });

  it('should fall back to openid when unionid is absent', async () => {
    const driver: WechatDriver = {
      code2Session: () => Promise.resolve({ openid: 'openid-only' }),
    };
    const service = new AuthWechatService(driver);
    await expect(service.resolveProviderUid('x')).resolves.toBe('openid-only');
  });

  it('should be deterministic for the mock driver', async () => {
    const service = new AuthWechatService(new MockWechatDriver());
    const a = await service.resolveProviderUid('same');
    const b = await service.resolveProviderUid('same');
    expect(a).toBe(b);
  });
});
