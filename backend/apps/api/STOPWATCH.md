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

## 已做（阶段 3-b：plans）

| 改动 | 文件 |
|---|---|
| `training_plan`（计划容器，UUIDv7 PK，`userId` FK，partial unique index 保证每人最多一份 active） | `src/training-plans/` + 迁移 `1756600200000-CreatePlans.ts` |
| `plan_version`（不可变快照，append-only，unique(planId, versionNumber)，存 `inputSnapshot` + `planJson` + `plannerVersion` + `generatedBy` + `changeReason`） | `src/plan-versions/`（只保留持久化层） |
| `POST /api/v1/plans`：已有 active → 追加新版本；否则建计划 + 版本 1。服务端不重算计划，只存快照（§9.2） | `training-plans.service.ts` |
| `GET /api/v1/plans/current` / `GET /api/v1/plans/current/versions`（游标分页）/ `GET /api/v1/plans/versions/:id`（跨用户按 404）/ `POST /api/v1/plans/current/archive` | `training-plans.controller.ts` |

单测：`src/training-plans`（7）—— `npx jest` 33 通过。build + lint 通过。

## 已做（阶段 3-c：workouts）

| 改动 | 文件 |
|---|---|
| `workout_session`（UUIDv7 PK，`userId` FK，`(userId, createdAt)` 索引，关联 `planVersionId` + `planDayIndex` 可空） | `src/workout-sessions/` + 迁移 `1756600300000-CreateWorkouts.ts` |
| `workout_set`（UUIDv7 PK，`sessionId` FK CASCADE，exerciseKey / exerciseName / setIndex / reps / weightKg / rir / isWarmup / completedAt） | `src/workout-sets/`（只保留持久化层） |
| 端点（都过 `AuthGuard('jwt')` + 逐条 ownership 校验，越权按 404）：<br>`POST /api/v1/workouts/sessions`（默认 in_progress，打 startedAt）<br>`GET /api/v1/workouts/sessions`（游标分页）<br>`GET /api/v1/workouts/sessions/:id`（含 sets）<br>`PATCH /api/v1/workouts/sessions/:id`（改 status / notes；→ completed 打 completedAt）<br>`POST /api/v1/workouts/sessions/:id/sets`（批量追加）<br>`PATCH /api/v1/workouts/sets/:setId`（修正）<br>`DELETE /api/v1/workouts/sets/:setId` | `workout-sessions.controller.ts` |

单测：`src/workout-sessions`（6）—— `npx jest` 39 通过。build + lint 通过。

## 已做（阶段 3-d：sync — 离线增量同步）

协议文档：`backend/packages/contracts/sync.md`（§9.1 的《同步协议 v1》）。

| 改动 | 文件 |
|---|---|
| `sync_event` 变更流表（每用户单调 `serverSeq`，`(userId, clientEventId)` 部分唯一索引做幂等） | `src/sync-events/` + 迁移 `1756600400000-CreateSyncEvent.ts` |
| `SyncEmitterService`：领域写成功后登记变更（best-effort，失败不回滚） | `src/sync-events/sync-emitter.service.ts` |
| `profiles` / `workout-sessions` 的写方法接了 `SyncEmitterService` + 可选 `WriteContext`（clientEventId / occurredAt） | 各自 service |
| `POST /api/v1/sync/batch`：逐条幂等（clientEventId 去重）→ 派发到领域 service → 返回逐条结果 + syncCursor | `src/sync/sync.service.ts` + controller |
| `GET /api/v1/sync/changes?cursor=&limit=`：按 serverSeq 拉增量 | 同上 |

单测：`src/sync`（6，内存 repo 全链路：apply / dedupe / reject / pull 分页 / 用户隔离）—— `npx jest` 45 通过。build + lint 通过。

### v1 已知限制（写进了 sync.md §"v1 已知限制"）
- 变更登记 best-effort，未和领域写同事务。
- `serverSeq` = MAX+1 + 唯一约束重试，高并发有重试成本。
- 没有 plan / body_log 同步；没有 WebSocket 主动推送；profile 冲突后写胜。

## 已做（阶段 4-a：media — 用户上传媒体）

| 改动 | 文件 |
|---|---|
| `media_object` 表（UUIDv7 PK，`userId` FK，`storageKey` 唯一，status pending/ready/rejected，moderationStatus） | `src/media-objects/` + 迁移 `1756600500000-CreateMediaObject.ts` |
| `StorageService` 抽象：`fake`（开发/测试，内存）/ `s3`（S3 兼容 —— 阿里云 OSS / 腾讯云 COS / AWS S3，`endpoint` 可配） | `src/media-objects/storage/` + `MEDIA_DRIVER` |
| 预签名直传（§9.13）：`POST /api/v1/media/upload-url` → 校验 content-type 白名单 + 按 purpose 的大小上限 → key 前缀 `userId/purpose/uuid.ext` + 短 TTL → 建 `media_object` pending → 返回 uploadUrl | `media-objects.service.ts` |
| `POST /api/v1/media/:id/complete` → HEAD 核对实际大小 / 类型（超限 / 不符 → rejected）→ status ready。幂等 | 同上 |
| `GET /api/v1/media/:id` → 元数据 + 读 URL（有 CDN 前缀走 CDN，否则预签名 GET） | 同上 |
| `assertUsable(userId, mediaId)` 供 social / chat 确认 media 属于该用户且 ready | 同上 |

单测：`src/media-objects`（10，用 FakeStorage 跑通请求→直传→complete→越权 全流程）—— `npx jest` 55 通过。build + lint 通过。

**未做**：内容审核（§9.5）—— `completeUpload` 里留了 TODO，要向 worker 投审核任务、回写 `moderationStatus`。缩略图 / 视频也没做（只图片）。

## 已做（阶段 4-b：notifications）

| 改动 | 文件 |
|---|---|
| `notification`（站内通知，UUIDv7 PK，`(userId, createdAt)` 索引，`data` jsonb deep-link）| `src/notifications/` + 迁移 `1756600600000-CreateNotifications.ts` |
| `notification_preference`（每用户一条，`pushEnabled` + `categories` jsonb opt-out + `quietHours`）| `src/notification-preferences/`（持久化 + service） |
| `device_token`（`(userId, token)` upsert，`platform` ios/android_fcm/android_vendor + `vendorChannel`）| `src/device-tokens/` |
| `PushService` 抽象：`console`（打日志）/ `off`。真实 APNs/FCM/厂商按 `platform` 分发，配置位留好（§9.4） | `src/notifications/push/` + `NOTIFICATIONS_PUSH_DRIVER` |
| `NotificationsService.notify(userId, {type, category, title, body, data})` —— 其它模块调它：落站内通知 + 按偏好 / 免打扰决定推送。推送 best-effort | `notifications.service.ts` |
| 端点（`AuthGuard('jwt')`）：`GET /api/v1/notifications`（游标，`unreadOnly`）/ `GET .../unread-count` / `POST .../read`（ids 或 all）/ `GET,PUT .../preferences` / `GET,POST .../devices` / `DELETE .../devices/:token` | `notifications.controller.ts` |

单测：`src/notifications`（7，内存 repo：推送/关推送/关分类/免打扰/未读计数/token upsert/推送失败不炸）—— `npx jest` 62 通过。build + lint 通过。

**未做**：真实推送通道（APNs / FCM / 国内厂商）；其它模块（workouts 提醒、plans 完成、social 互动）还没调 `notify()`——那是各模块自己接的事。

## 还没做（下一步）

- 把 `IdempotencyInterceptor` 挂成全局（`APP_INTERCEPTOR`）——现在只是文件，未启用。
- OpenAPI 3.1 spec 导出到 `backend/packages/contracts/`。
- `user` 防枚举：加 `publicId uuid` 列。
- 阶段 5：`social` / `chat`（WebSocket gateway）。
- 内容审核接入（阿里云 / 腾讯云内容安全 API），media + social + chat 都要。
- 各模块接 `NotificationsService.notify()`（训练提醒、计划就绪、互动）。
- 账号合并：手机号 + 微信同一人 = 两个 user 行，合并流程待排期。

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
