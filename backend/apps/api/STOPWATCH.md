# Stopwatch `apps/api` —— 相对 brocoders/nestjs-boilerplate 的改动

**基线 commit**：`9620f159eefe38f47747d02ab162852367c5472c`（`brocoders/nestjs-boilerplate`，1.2.0）
方案见 [`ADAPTATION_PLAN.md`](./ADAPTATION_PLAN.md)。

## 已做（阶段 1：地基）

| 改动 | 文件 |
|---|---|
| PostgreSQL only（去 Mongoose + document 持久化 + all-db 生成器） | 一次性裁剪（`.install-scripts/` 已随裁剪脚本一并删除） |
| 去 Facebook 登录（保留 Google / Apple） | 同上 |
| **UUIDv7** 主键生成器（无第三方依赖，RFC 9562） | `src/common/id/uuid.ts` |
| **游标分页**（禁 deep OFFSET） | `src/common/pagination/cursor.ts` |
| **Idempotency-Key** 拦截器（Redis 去重，所有 mutating 端点） | `src/common/idempotency/idempotency.interceptor.ts` |
| **Redis** 全局模块（OTP / 限流 / token 撤销 / 在线状态 / WS 广播） | `src/redis/` + `REDIS_URL` |
| 单机开发栈：postgis + redis + api + planner | `backend/deploy/compose/dev.compose.yaml` |

单测：`src/common/**/*.spec.ts`（uuid v7、cursor）—— `npx jest src/common` 通过。
`npm run build` 通过。

## 已做（阶段 2：认证 —— 手机号 + 微信）

| 改动 | 文件 |
|---|---|
| `user_identities` 多身份表（一个 user 挂多条 provider+providerUid，唯一约束） | `src/user-identities/`（生成器 relational 骨架 + 手改）+ 迁移 `1756600000000-CreateUserIdentity.ts` |
| `AuthService.validateIdentityLogin(provider, providerUid)`：命中 identity → 登录；否则建号 + 建 identity | `src/auth/auth.service.ts`（抽出 `issueSession()` 私有方法） |
| **手机号 OTP 登录**：`POST /api/v1/auth/phone/send-code` + `/login` | `src/auth-phone/` |
| OTP 服务：码存 Redis TTL 5min + 三层限流（60s 冷却 / 每号每日 5 / 每 IP 每时 20）+ 5 次错码作废 | `src/common/otp/otp.service.ts` |
| 短信 driver 抽象：`console`（打日志）实现；`aliyun` / `tencent` 配置位已留，待密钥 | `src/common/sms/` + `SMS_DRIVER` |
| **微信登录**：`POST /api/v1/auth/wechat/login`（code → openid/unionid，优先 unionid） | `src/auth-wechat/` |
| 微信 driver：`mock`（开发，按 code 造稳定 uid）/ `http`（真实 `sns/oauth2/access_token`） | `src/auth-wechat/wechat.driver.ts` + `WECHAT_DRIVER` |
| `AuthProvidersEnum` 加 `phone` / `wechat` | `src/auth/auth-providers.enum.ts` |
| 新环境变量：`SMS_*` / `AUTH_PHONE_EXPOSE_CODE` / `WECHAT_*` | `env-example-relational` |

单测：`src/common/otp`（7）、`src/auth-phone`（3）、`src/auth-wechat`（3）—— `npx jest` 20 通过。
`npm run build` + `npm run lint` 通过。

**未接真实渠道**：短信只有 console driver；微信只有 mock driver + 未实测的 http driver。接阿里云/腾讯云短信、微信开放平台密钥时补 driver 实现（配置位已就绪）。

## 已做（阶段 3-a：profiles）

| 改动 | 文件 |
|---|---|
| `profile` 表（UUIDv7 PK，`userId` 唯一，1:1 到 user，ON DELETE CASCADE） | `src/profiles/` + 迁移 `1756600100000-CreateProfile.ts` |
| 问卷稳定字段：sex / birthdate / heightCm / goal / experienceLevel / minutesPerSession / mealsPerDay / cookingAccess / targetWeightKg / injuriesText / equipment[] / dietaryRestrictions[] | `profile.entity.ts`（equipment / dietaryRestrictions 用 jsonb） |
| 身体数据同意（§9.6）：`bodyDataConsentAt` + `bodyDataConsentVersion`，`bodyDataConsent:true` 时打时间戳 | `profiles.service.ts` |
| `GET /api/v1/profile/me`（未建 → 404）+ `PUT /api/v1/profile/me`（upsert，省略字段不当作清空） | `profiles.controller.ts`（`AuthGuard('jwt')`） |

单测：`src/profiles`（6）—— `npx jest` 26 通过。build + lint 通过。

变会随时间的体重 / 体脂 / 围度不在 profile，走后面的 body log。

## 还没做（下一步）

- 把 `IdempotencyInterceptor` 挂成全局（`APP_INTERCEPTOR`）——现在只是文件，未启用。
- 阶段 3-b/c/d：`plans`（+ planner_version + 输入快照）/ `workouts` / `sync`。
- 账号合并：现在同一个人用手机号 + 微信会得到两个 user 行。合并流程（老账号验证后 link 新 identity）待排期。
- OpenAPI 3.1 spec 导出到 `backend/packages/contracts/`。
- `user` 防枚举：后续加 `publicId uuid` 列，不动 PK。

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
