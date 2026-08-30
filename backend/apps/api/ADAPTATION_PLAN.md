# `apps/api` 改造方案 —— 基于 `brocoders/nestjs-boilerplate`

> 状态：**待确认**。确认后再动手 clone + 改。
> 对齐《Stopwatch 后端架构与 Docker 部署方案》。

## 0. 为什么选它

`brocoders/nestjs-boilerplate`（⭐10k+，活跃）：
- NestJS + TypeScript + **TypeORM + PostgreSQL** + Docker + GitHub Actions CI —— 跟架构文档技术栈一致
- 自带：邮箱注册登录、社交登录（Google / Apple / Facebook）、**RBAC（admin/user）**、
  session/refresh-token、i18n、Nodemailer 邮件、文件上传（本地 + S3）、Swagger、E2E + 单测、
  `.hygen` 代码生成器（一条命令生成一个规范 CRUD 模块）
- 我们要做的主要是「**加领域模块 + 换认证方式**」，不是从零搭地基

## 1. 直接留用（基本不改）

| 模块 | 用途 |
|---|---|
| `auth` | 核心认证：JWT、refresh token、guard、`@AuthUser()` |
| `auth-apple` | iOS 端 Apple 登录（App Store 要求） |
| `auth-google` | 国际版 Google 登录 |
| `users` / `roles` / `statuses` | 用户、角色、状态（RBAC 基础） |
| `session` | 多设备 session / token 撤销 |
| `mail` / `mailer` | 邮件（找回、通知兜底） |
| `files` | 头像 / 图片直传抽象（driver 换 MinIO/S3） |
| `i18n` / `config` / `database` / `utils` | i18n、配置、TypeORM 连接、分页等工具 |
| `.hygen` 生成器、Docker、CI、ESLint/Prettier/Commitlint | 工程规范 |

## 2. 去掉 / 改造

- **删 Mongoose 分支**：只走关系型（TypeORM + Postgres）。boilerplate 有双 ORM，砍掉 document 版的 compose / 模块变体。
- **`auth-facebook`**：国内没用，删（或留着不启用）。
- **Postgres 镜像换 `postgis/postgis`**：为「附近的人」（架构文档 v2）预留 PostGIS。
- **加 Redis**：boilerplate 默认没有。OTP、限流、token 撤销、在线状态、跨实例广播都要它。
- **加 RabbitMQ**（或先用 Redis Streams / BullMQ 顶着）：推送、图片处理、审核、**统计聚合**（喂同类对标）等异步任务。

## 3. 新增认证模块

| 新模块 | 说明 |
|---|---|
| `auth-phone` | **手机号 + 短信 OTP**（国内主渠道）。OTP 存 Redis（TTL 5min + 限流 + 尝试次数）。短信商：阿里云 / 腾讯云 SMS，driver 抽象（本地开发用 console driver 打印验证码） |
| `auth-wechat` | **微信登录**。App 端：微信开放平台 `code` → `access_token` + `openid`/`unionid`。用 `unionid` 关联账号 |

账号合并策略：一个 `users` 行可挂多个 `user_identities`（provider + provider_uid），手机号 / 微信 / Apple / Google 都是 identity。对齐架构文档 §6 的 `users, user_identities, user_devices, refresh_tokens`。

## 4. 新增领域模块（架构文档 §1 / §6）

按优先级（架构文档「首期建议」列）：

**必须（首期）**
- `profiles` —— `user_profiles`, `user_settings`：身体资料、训练目标、隐私权限。高敏身体数据与账号权限分表。
- `plans` —— `plan_inputs`（问卷输入快照）, `training_plans`, `plan_versions`（不覆盖旧计划）, `exercises`。
  存 `planner_version` + 输入快照 + 结果 + 调整原因 + 生成端（Dart 本地 / Python 服务）。
- `workouts` —— `workout_sessions`, `workout_sets`, `workout_events`（事件追加，尽量不覆盖）。
- `sync` —— 离线增量同步：客户端 Outbox → 批量上传 → 按 `event_id` 去重 → 返回 `sync_cursor` → 拉增量。
  架构文档 §7 说这是**首期最重要的基础能力**。
- `media` —— 图片 / 视频直传（预签名 URL，API 不代理大文件）、缩略图、审核 hook、CDN。
- `notifications` —— `notifications`, `notification_preferences` + FCM/APNs。

**当前需要**
- `social` —— `social_posts`, `post_comments`, `post_likes`(唯一约束 user_id+post_id), `follows`, `blocks`, `reports`。
- `chat` —— `conversations`, `conversation_members`, `messages`（会话内序号，不靠客户端时间排序）, `message_receipts` + **WebSocket gateway**（未读数、在线事件）。

**v1.1 / v2**
- `diet` —— `meal_logs`, `food_items`, `food_barcode_cache` + 条码缓存 + 照片识别任务（异步）。
- `nearby` —— `venues`, `user_location_presence`, `checkins`（PostGIS，模糊位置，位置过期，不长期存精确坐标）。

**上线前**
- `admin` —— 用户 / 举报 / 审核 / 运营配置 / 审计。
- `analytics` —— 指标 / 事件 / 调用链（OpenTelemetry）。

**基础设施表**：`outbox_events`（领域事件外发）、`audit_logs`。

## 5. 跨切面（架构文档要求）

- **主键 UUIDv7 / ULID**，时间统一 UTC。
- **游标分页**，禁 deep OFFSET。→ 加一个 `CursorPaginate` 工具（boilerplate 是 offset 分页，要换）。
- 写操作带 **`Idempotency-Key`** header → 中间件 + Redis 去重。
- 软删除保留 tombstone（离线同步要）。
- 模块不跨边界直接改别的模块的表，走服务接口 / 领域事件（`outbox_events`）。
- **OpenAPI 3.1** 作为 Flutter + 管理后台 + 后端的共同契约（boilerplate 已有 Swagger，锁 3.1 + 导出 spec 到 `packages/contracts`）。

## 6. 计划引擎 + 同类对标怎么接

- **Dart 本地引擎**：离线出计划，不变。
- **Python `services/planner`**（已在仓库，PR #10）：服务端标准版计划复现 + 同类对标。
  - `apps/api` 的 `plans` 模块保存输入快照 + `planner_version`；需要复现时调 planner 服务 `/v1/plan/replay`（待建）。
  - `workouts` / `plans` 的 check-in 结果 → `apps/api` 的 worker 脱敏 → POST 到 planner `/v1/cohort/submit`。
  - 客户端要软提示时，`apps/api` 代理 planner 的 `/v1/cohort/benchmark`（或客户端直连 planner，带匿名 device 标识）。
- **共用版本化 JSON Schema**：`packages/contracts/planner/*.schema.json`，Dart / Python / TS 三端校验同一份。

## 7. 目录（对齐架构文档 §4）

```
backend/
  apps/
    api/                    ← 本方案（NestJS）
      src/
        auth/ auth-apple/ auth-google/ auth-phone/ auth-wechat/
        users/ profiles/ roles/ statuses/ session/
        plans/ workouts/ sync/
        social/ chat/
        media/ notifications/
        diet/ nearby/ admin/ analytics/
        outbox/ common/(idempotency, cursor-paginate, uuidv7)
        config/ database/ i18n/ mail/ mailer/ utils/
      test/
      Dockerfile  docker-compose*.yaml
    worker/                 ← 异步任务（推送 / 图片 / 审核 / 统计聚合）
  services/
    planner/               ← 已有（PR #10）
  packages/
    contracts/             ← OpenAPI + planner JSON Schema
    database/              ← 共享迁移 / 种子（若 worker 也用）
  deploy/
    compose/
      dev.compose.yaml     ← api + worker + postgis + redis + rabbitmq + minio + planner
      prod.compose.yaml
```

## 8. 分阶段（对齐架构文档 §8，我能做的部分）

1. **地基**：clone boilerplate → 砍 Mongoose/facebook → 换 postgis 镜像 → 加 redis/rabbitmq 到 compose →
   UUIDv7 + 游标分页 + Idempotency 中间件 → OpenAPI 3.1 导出。
2. **认证**：`auth-phone`（console driver）+ `auth-wechat`（stub + 真实 code 交换）+ `user_identities` 多身份。
3. **核心域**：`profiles` → `plans`（+ planner_version / 输入快照）→ `workouts` → `sync`（Outbox + cursor）。
4. **媒体 + 通知**：`media`（预签名直传）+ `notifications`（FCM/APNs stub）。
5. **社交 + 聊天**：`social` + `chat`（WebSocket gateway）。
6. **接 planner**：worker 里 check-in 结果脱敏转投 `/v1/cohort/submit`；`plans` 复现调用。

每一步：迁移 + 种子 + E2E 测试 + 更新 `packages/contracts` 的 OpenAPI。

> 短信 / 微信 / FCM / APNs / S3 的真实密钥不进代码，走 `.env` + driver 抽象；开发环境用 console / mock driver。

---

## 要你拍板

- 阶段 1–3（地基 + 认证 + 核心训练域）先做，社交 / 聊天 / 饮食 / 附近 往后放 —— 同意？
- 异步任务：先用 **BullMQ（Redis）** 顶着，RabbitMQ 等真有压力再上 —— 同意？（少一个组件）
- `services/planner`（Python 同类对标）保留独立服务，不并进 NestJS —— 同意？
