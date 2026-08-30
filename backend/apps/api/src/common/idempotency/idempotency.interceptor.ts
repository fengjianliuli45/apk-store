import {
  CallHandler,
  ConflictException,
  ExecutionContext,
  Inject,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { Observable, from } from 'rxjs';
import { switchMap, tap } from 'rxjs/operators';
import type Redis from 'ioredis';
import type { Request } from 'express';
import { REDIS } from '../../redis/redis.module';

const TTL_SECONDS = 24 * 60 * 60;
const HEADER = 'idempotency-key';

/**
 * 所有 mutating 端点（POST/PUT/PATCH/DELETE）带 `Idempotency-Key` header。
 * 同 key + 同用户：首次执行并缓存响应；重放直接返回缓存；执行中重放 → 409。
 * （ADAPTATION_PLAN §5 / §9.1：所有写操作，不是选择性）
 */
@Injectable()
export class IdempotencyInterceptor implements NestInterceptor {
  constructor(@Inject(REDIS) private readonly redis: Redis) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const req = context.switchToHttp().getRequest<Request>();
    if (['GET', 'HEAD', 'OPTIONS'].includes(req.method)) {
      return next.handle();
    }
    const key = (req.headers[HEADER] as string | undefined)?.trim();
    if (!key) {
      // 没带 key 就放行（客户端应带；上线前可改成 400 强制）
      return next.handle();
    }
    const userId =
      (req as unknown as { user?: { id?: string } }).user?.id ?? 'anon';
    const redisKey = `idem:${userId}:${req.method}:${req.path}:${key}`;

    return from(
      this.redis.set(redisKey, 'pending', 'EX', TTL_SECONDS, 'NX'),
    ).pipe(
      switchMap((acquired) => {
        if (acquired === null) {
          return from(this.redis.get(redisKey)).pipe(
            switchMap((cached) => {
              if (!cached || cached === 'pending') {
                throw new ConflictException(
                  '相同 Idempotency-Key 的请求正在处理，请勿重复提交',
                );
              }
              return from(Promise.resolve(JSON.parse(cached) as unknown));
            }),
          );
        }
        return next.handle().pipe(
          tap({
            next: (body) => {
              void this.redis.set(
                redisKey,
                JSON.stringify(body ?? null),
                'EX',
                TTL_SECONDS,
              );
            },
            error: () => {
              void this.redis.del(redisKey);
            },
          }),
        );
      }),
    );
  }
}
