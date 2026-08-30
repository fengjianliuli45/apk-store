# Stopwatch `apps/api` —— 相对 brocoders/nestjs-boilerplate 的改动

**基线 commit**：`9620f159eefe38f47747d02ab162852367c5472c`（`brocoders/nestjs-boilerplate`，1.2.0）
方案见 [`ADAPTATION_PLAN.md`](./ADAPTATION_PLAN.md)。

## 已做（阶段 1：地基）

| 改动 | 文件 |
|---|---|
| PostgreSQL only（去 Mongoose + document 持久化 + all-db 生成器） | 跑了 `.install-scripts/run-stopwatch.ts` |
| 去 Facebook 登录（保留 Google / Apple） | 同上 |
| **UUIDv7** 主键生成器（无第三方依赖，RFC 9562） | `src/common/id/uuid.ts` |
| **游标分页**（禁 deep OFFSET） | `src/common/pagination/cursor.ts` |
| **Idempotency-Key** 拦截器（Redis 去重，所有 mutating 端点） | `src/common/idempotency/idempotency.interceptor.ts` |
| **Redis** 全局模块（OTP / 限流 / token 撤销 / 在线状态 / WS 广播） | `src/redis/` + `REDIS_URL` |
| 单机开发栈：postgis + redis + api + planner | `backend/deploy/compose/dev.compose.yaml` |

单测：`src/common/**/*.spec.ts`（uuid v7、cursor）—— `npx jest src/common` 通过。
`npm run build` 通过。

## 还没做（下一步）

- **把现有实体主键从自增 int 换成 UUIDv7**（`user` / `session` / `role` / `status` / `file`）——
  boilerplate 用 `@PrimaryGeneratedColumn()`。改动面涉及 entity + domain mapper + DTO + seed。
  建议在做 `auth-phone`（要动 `users` / `user_identities`）时一起换。
- 把 `IdempotencyInterceptor` 挂成全局（`APP_INTERCEPTOR`）——现在只是文件，未启用。
- 阶段 2：`auth-phone`（短信 OTP，console driver）、`auth-wechat`、`user_identities` 多身份。
- 阶段 3：`profiles` / `plans`（+ planner_version + 输入快照）/ `workouts` / `sync`。
- OpenAPI 3.1 spec 导出到 `backend/packages/contracts/`。

## 上游跟进流程（ADAPTATION_PLAN §9.11）

我们 fork 了 boilerplate，重度改造后拉不动 upstream。至少 **认证 + 依赖** 两块要跟：

```bash
# 每月 / 有 CVE 时
git remote add upstream https://github.com/brocoders/nestjs-boilerplate  # 一次
git fetch upstream
git log --oneline 9620f159..upstream/main -- src/auth src/session src/auth-apple src/auth-google
npm audit
# 有安全相关改动 → 手动挑 patch 应用到 apps/api，更新本文件的基线 commit
```
