import { Global, Module, OnModuleDestroy } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';
import { AllConfigType } from '../config/config.type';

export const REDIS = Symbol('REDIS');

/**
 * 全局 Redis 连接。用途（ADAPTATION_PLAN §2 / §9.7 / §9.8）：
 * OTP、限流、token 撤销、Idempotency-Key、在线状态、WebSocket 跨实例广播。
 */
@Global()
@Module({
  providers: [
    {
      provide: REDIS,
      inject: [ConfigService],
      useFactory: (config: ConfigService<AllConfigType>) => {
        const url = config.getOrThrow('redis.url', { infer: true });
        return new Redis(url, { maxRetriesPerRequest: 3, lazyConnect: false });
      },
    },
  ],
  exports: [REDIS],
})
export class RedisModule implements OnModuleDestroy {
  constructor() {}
  async onModuleDestroy() {
    /* ioredis 连接由进程退出回收；如需优雅关闭可在此 quit() */
  }
}
