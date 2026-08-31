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

1. ✅ **地基**（PR #11）：clone boilerplate → 砍 Mongoose/facebook → postgis 镜像 → redis 到 compose →
   UUIDv7 生成器 + 游标分页 + Idempotency 拦截器（文件就绪，未全局挂）。OpenAPI 导出待做。
2. ✅ **认证**（PR #12）：`auth-phone`（console SMS driver + Redis OTP + 三层限流）+ `auth-wechat`（mock/http driver）+ `user_identities` 多身份表 + `AuthService.validateIdentityLogin`。未接真实短信/微信密钥。
3. ✅ **核心域**（PR #13–#16）：`profiles`（#13）→ `plans` + 版本快照（#14）→ `workouts`（#15）→ `sync`（#16，协议见 `backend/packages/contracts/sync.md`）。
4. ✅ **媒体 + 通知**：`media`（#18）+ `notifications`（#19：站内通知 + 偏好/免打扰 + device_token + PushService 抽象；真实 APNs/FCM/厂商待接）。
5. **社交 + 聊天**：`social`（Postgres 自写）+ `chat`（见 §9.15 / §11：小服务器上 OpenIM 不可行，聊天先延后或最小 1:1）← 下一步，**先看 §11**。
6. **接 planner**：check-in 结果脱敏转投 `/v1/cohort/submit`；`plans` 复现调用。planner 服务本身按 §11 **延后部署**。

每一步：迁移 + 种子 + E2E 测试 + 更新 `packages/contracts` 的 OpenAPI。

> 短信 / 微信 / FCM / APNs / S3 的真实密钥不进代码，走 `.env` + driver 抽象；开发环境用 console / mock driver。

---

## 要你拍板

- 阶段 1–3（地基 + 认证 + 核心训练域）先做，社交 / 聊天 / 饮食 / 附近 往后放 —— **已确认 ✅**
- 异步任务：先用 **BullMQ（Redis）** 顶着，RabbitMQ 等真有压力再上 —— **已确认 ✅**
- `services/planner`（Python 同类对标）保留独立服务，不并进 NestJS —— **已确认 ✅**

---

## 9. 以后会咬人的问题（现在就得定，否则后期返工很痛）

按「不定好后期改动成本」从高到低。

### 9.1 离线同步的冲突模型（最痛）
- **问题**：多设备并发编辑、客户端时钟漂移、tombstone 何时回收、事件乱序到达。协议弱了以后重写要动全部客户端。
- **现在要做**：
  - 训练记录 = **事件追加（append-only）**，几乎不 update；服务端按 `event_id` 幂等去重。
  - 每条写操作带 **`Idempotency-Key`**（所有 mutating 端点，不是选择性）。
  - 设置 / 资料这类可变数据：用 **版本号（lamport / server-assigned）** 解冲突，不靠 `updated_at` 时间戳。
  - 消息用**会话内单调序号**，绝不靠客户端时间排序。
  - 点赞 / 关注靠 **DB 唯一约束**（`user_id + post_id`）而不是应用层查重。
  - tombstone 保留期写进配置（如 90 天），到期后台清理，客户端拉不到 = 已删。
  - 先写一份《同步协议 v1》放 `packages/contracts/sync.md`，Dart / TS 都照它实现。

### 9.2 planner_version 三端漂移
- **问题**：Dart 引擎、Python 引擎、已存的计划 —— 任一升级另两个没跟上，旧计划无法复现、同类数据不可比。
- **现在要做**：
  - 每份 `training_plans` 存 `planner_version` + **输入快照**（问卷原始输入），不只存结果。
  - CI 加一道 **Dart↔Python 逐字对齐门禁**（本仓库已有对齐脚本，接进 CI）。
  - JSON Schema 版本化放 `packages/contracts/planner/`，三端（Dart / Python / TS 校验）用同一份。
  - 服务端计划生成**只在 Python `services/planner`**，NestJS 永不重实现。

### 9.3 同类对标：数据可比性 + 冷启动 + 投毒
- **可比性**：不同 `planner_version` 的 e1RM% 用的负荷模型不一样，不能混桶。→ cohort 键**加 `metric_schema_version`**（跟 planner 大版本绑），换版本另起桶。
- **冷启动**：头几个月没有任何桶到 20 人，功能对用户是空的。→ 先用**文献基线**（Helms / RP 的典型进度区间）做占位，标注「参考值，非同类实测」；实测桶够了再切换。写进 `services/planner` 的 config。
- **投毒 / 刷量**：匿名上报被脚本灌假数据会歪百分位。→ 上报走 `apps/api` 转发（带 account 上下文做限流 + 异常过滤：单设备频率、离群值裁剪 p1/p99），不让客户端直连 planner 的 submit。benchmark 查询可以直连或缓存。

### 9.4 中国推送：FCM 在国内不通
- **问题**：Android 国内 FCM 基本收不到。只做 FCM = 国内用户收不到训练提醒 / 互动通知。
- **现在要做**：`notifications` 的 push driver 抽象成多通道：iOS→APNs、Android 国际→FCM、**Android 国内→厂商推送（小米 / 华为 / OPPO / vivo）或聚合（个推 / 极光）**。首期至少接一个国内聚合通道。

### 9.5 内容安全（社交 / 头像 / 聊天）—— 法律要求
- **问题**：国内 UGC 必须过内容审核（图文 + 昵称 + 简介），漏审有下架风险。
- **现在要做**：`media` 上传 + `social` 发帖 + `chat` 发图，全部过 **内容安全 API（阿里云 / 腾讯云）**同步预审 + 异步复审。审核结果进 `reports` / 审计。别等社交模块做完再补。

### 9.6 合规（PIPL）—— 身体数据是敏感个人信息
- **现在要做**：
  - 身体数据（体重 / 体脂 / 围度 / 伤病）单独存表、单独同意勾选、单独授权开关（架构文档已提"高敏身体数据与账号权限分离"，落实到 schema）。
  - **注销**要真删 / 匿名化，不是软删标记；写一条注销 job 走全模块级联。
  - 数据导出接口（用户可下载自己的全部数据）。
  - 数据**境内存储**（服务器选国内区）。
  - 未成年人：`age ≥ 16` 才允许注册（引擎已按此），16–18 加监护提示。
  - 保留**同意记录**（时间 / 版本 / 条款哈希）。

### 9.7 OTP 端点是头号攻击面（会烧真钱）
- **问题**：短信轰炸机刷 `/auth/phone/send-code`，每条短信都是钱。
- **现在要做**：per-phone（60s 一条 / 天 5 条）+ per-IP + 全局 QPS 三层限流（Redis），失败 N 次上**图形 / 滑块验证码**，异常号段直接拒。第一版就要有，不能后补。

### 9.8 WebSocket 多实例
- **问题**：单实例能跑通，加副本后跨实例的在线状态 / 未读推送就断了。
- **现在要做**：WebSocket gateway 一开始就挂 **Redis adapter**（`@socket.io/redis-adapter` 或等价），本地也用 Redis 跑，别等扩容才加。

### 9.9 UUIDv7 / 主键策略 —— 已修订（2026-08-31，阶段 2）
- **问题**：boilerplate 默认 `user` / `session` 自增 int，`file` 是 uuid v4；有数据后换 PK 策略几乎不可能。
- **原计划**：地基阶段把所有实体 PK 换成 UUIDv7。
- **实际决定**：boilerplate 核心表（`user` / `session` / `role` / `status`）**保持自增 int**。
  换 `user.id` 类型会波及几十处 `User['id']: number` + mapper + DTO + seed，且大幅偏离 upstream，跟 §9.11 冲突。
  取舍：
  - Stopwatch **自有领域表一律 UUIDv7**（`src/common/id/uuid.ts` 的 `newId()` + `@PrimaryColumn('uuid')` + `@BeforeInsert`）。`user_identity` 已按此。
  - 领域表的 `userId` 外键就存 int（指向 `user.id`），只在内部用，不对外暴露。
  - `user.id` 若要防枚举（增长速率 / 遍历），后续加 `publicId uuid` 唯一列对外，不动 PK。成本低（加列 + 响应映射），且现在没客户端缓存 id。
- `.hygen` 生成器出的 entity 默认还是 `@PrimaryGeneratedColumn('uuid')`（DB 端 uuid v4）——**手动改成** `@PrimaryColumn('uuid')` + `newId()`（见 CLAUDE.md）。

### 9.10 Flutter 本地存储迁移
- **问题**：架构文档 §7 提到业务数据要从 SharedPreferences 迁到 SQLite/Drift。上线后带着 SharedPreferences 数据的用户，迁移有风险。
- **现在要做**：App 接后端之前**先做本地存储迁移**（Drift / Isar），并写一次性迁移逻辑 + 回滚方案。这是 App 那条线的活，但要在同步协议定稿前排期。

### 9.11 fork 了 boilerplate 之后的上游安全更新
- **问题**：重度改造后拉不动 upstream 的安全补丁。
- **现在要做**：记录 fork 基线 commit，`docs/` 里写一份《upstream 跟进流程》（定期 diff `brocoders/main` 的 `src/auth*`、依赖版本、CVE），至少认证 / 依赖这两块要跟。

### 9.12 队列抽象（为了以后换 RabbitMQ 不痛）
- **现在要做**：worker 里所有 job 走一层薄抽象（`enqueue(name, payload)` / `handler`），底层现在是 BullMQ，以后换 RabbitMQ 只改抽象层实现，不动业务代码。

### 9.13 媒体直传的安全
- **问题**：预签名 URL 用错（范围太宽 / TTL 太长 / 不校验 content-type、大小）会被当免费图床。
- **现在要做**：预签名限定 `key 前缀 + content-type + max-size + 短 TTL`，上传完成回调校验实际对象，再落 `media_objects`。

---

## 9.14 各模块的现成方案（能接就别自己写）

| 模块 | 现成方案 | 状态 |
|---|---|---|
| **通知** | `Novu`（MIT，FCM/APNs/SMS 多渠道 + 工作流编排，Docker 自托管） | ✅ 接。国内厂商推送 / 微信自己加 provider |
| **聊天 / 消息** | `OpenIM`（Apache 2.0，Go，国内团队，SDK 全，REST + Webhook 接入）| ✅ 接（见 §9.15 调研）。Tinode GPL 别用 |
| **媒体存储** | `MinIO`（S3 兼容自托管） | ✅ 接。预签名直传标准做法 |
| **内容审核** | 阿里云 / 腾讯云内容安全（云 API，非开源项目） | ✅ 接 |
| **条码 / 营养库** | `Open Food Facts`（DB + API，可自托管 Product Opener + 每日导出） | ✅ 接 |
| **管理后台** | `AdminJS` / `react-admin` / `Refine`（接 NestJS + Postgres 自动 CRUD） | ✅ 接 |
| **监控** | Prometheus + Grafana + Loki + Tempo（架构文档 §2.3 已列） | ✅ 标准栈 |
| **附近的人** | PostGIS（Postgres 扩展，dev.compose 已用 postgis 镜像） | ✅ 不用单独项目 |
| **认证 · 邮箱/Google/Apple** | boilerplate 自带 | ✅ 留用 |
| **认证 · 手机 OTP** | 逻辑简单（Redis 存码 + 限流），自己写；短信走阿里/腾讯 SDK | 🟡 自己写 |
| **认证 · 微信登录** | 没有可直接用的"微信登录模块"；阿里有 SDK，`code→openid/unionid` 自己接 | 🟡 自己写 |
| **社交动态流** | 没有成熟开源方案（见 §9.15）。`Stream-Framework` 要 Cassandra + 多年没维护 | 🔴 自己写（Postgres + 扇出） |
| **异步队列** | `BullMQ`（现成库） | ✅ 接 |
| **离线同步协议** | 没有能直接套的（Yjs/Automerge 是文档协同，不适合训练记录 / 计划版本）。见 §9.1 自己定协议 | 🔴 自己写 |
| **计划 / 训练记录**（问卷快照 / 计划版本 / 组数场次） | Stopwatch 独有领域，没现成的。用 boilerplate 生成器出 CRUD 骨架，逻辑自己写 | 🔴 自己写 |
| **拍照识别食物** | 模型用现成（云 API / 开源模型 + nutrition5k 类数据集），业务串联自己写 | 🔴 串联自己写 |

**结论**：能接的都接现成的（通知 / 聊天 / 存储 / 审核 / 条码 / 后台 / 监控）。真正要自己写的是
**「计划 + 训练记录 + 离线同步」** —— 正好是 Stopwatch 的核心，也是别人替不了的。

### 授权（商用能不能用）—— 必查

| 组件 | 授权 | 商用 | 备注 |
|---|---|---|---|
| `brocoders/nestjs-boilerplate` | MIT | ✅ | |
| `Novu`（通知） | MIT 核心 | ✅ | 企业版 SAML/审计要付费，我们用的通知功能 MIT |
| `OpenIM`（聊天） | Apache 2.0 | ✅ | **首选** |
| `Tinode`（聊天备选） | GPL-3.0 | ❌ | copyleft，别用，用 OpenIM |
| `AdminJS` / `react-admin` / `Refine` | MIT | ✅ | |
| `BullMQ` | MIT | ✅ | |
| `Prometheus` | Apache 2.0 | ✅ | |
| `Grafana` / `Loki` / `Tempo` | **AGPLv3** | ⚠️ | 内部监控用（不面向 App 用户）风险低；保守用 `VictoriaMetrics`（Apache 2.0） |
| **`MinIO`（对象存储）** | **AGPLv3** | ⚠️ | 跟 wger 一样。**改用阿里云 OSS / 腾讯云 COS**（S3 接口 + 境内合规），自托管则 `SeaweedFS`（Apache 2.0） |
| `Open Food Facts` | 数据 ODbL / 软件 AGPL | ⚠️ | 用它的 **API 查营养** OK；别自托管 Product Opener、别二次分发改过的数据库 |
| PostgreSQL | PostgreSQL License | ✅ | |
| PostGIS | GPL-2.0 | ✅ | 作为 DB 扩展跑，商用 SaaS 标准做法 |
| `Stream-Framework`（动态流） | BSD-3 | ✅ | 但不推荐（Cassandra + 维护弱），建议 Postgres 自写 |

**要改的**：`media` 模块的存储 driver 直接对接**阿里云 OSS / 腾讯云 COS**，不引 MinIO（`dev.compose` 里本地开发可保留一个 SeaweedFS 或 MinIO 容器仅供开发，生产走云 OSS）。

## 9.15 阶段 5（social + chat）现成方案调研（2026-08-31）

用户要求："优先调研有没有已经成熟的解决方案"。结论：**聊天有，社交流没有。**

### 聊天 / IM

| 方案 | 授权 / 商用 | 形态 | 适不适合 |
|---|---|---|---|
| **OpenIM**（open-im-server） | **Apache 2.0，✅ 商用免费** | Go 微服务，自托管，客户端 SDK 全（含 Flutter）。前微信技术团队，贴国内合规 | ✅ **成熟、对口**。有 REST API（后端建用户 / 发 IM token）+ Webhook（消息 / 关系 / 推送 前后回调 → 接我们的审核 + notifications）。用户系统保留在 `apps/api`，OpenIM 只管消息 |
| Tinode | GPL-3.0 | Go 自托管 | ❌ copyleft，商用别碰 |
| Rocket.Chat / Mattermost / Matrix-Synapse | 各异（RC 社区版限 100 并发 + MongoDB；Matrix 偏联邦、重） | 团队协作聊天产品 | ❌ 形态不对（要的是 App 内嵌 1:1 私信，不是 Slack） |
| Sendbird / CometChat / GetStream Chat / MirrorFly | 商业 SaaS 或付费自托管授权 | 托管 | ❌ 付费 / 数据不在自己手 |
| 自己在 NestJS 写 | —— | `@nestjs/websockets` + `socket.io` + `@socket.io/redis-adapter` | 🟡 全控但要自己写会话 / 消息序号 / 回执 / 未读 / 在线 / 离线投递 / 推送联动，工作量大、后期维护 |

**OpenIM 的代价**：它是一整个独立服务，自带 MongoDB + Kafka + Redis + MinIO（对象存储那块可换云 OSS）。用户单服务器现在扛这一套偏重。

**两条路，要用户拍板：**
- **A（推荐，若服务器扛得住）**：现在就接 OpenIM 独立服务（像 planner 一样）。`apps/api` 登录后调 OpenIM REST 建用户 + 发 token；OpenIM 的消息前置回调 → 内容审核；推送回调 → 我们的 `NotificationsService`。聊天完全不在 NestJS 写。
- **B（轻起步）**：先在 NestJS 写**最小 1:1 私信**（`conversation` / `conversation_member` / `message`〔会话内单调序号，§9.1〕/ `message_receipt` + socket.io + redis-adapter），群聊 / 富功能不做，以后量大了整体换 OpenIM。

### 社交动态流

**没有可直接用的成熟开源方案。**
- `Stream-Framework`（BSD-3，GetStream 的开源版）—— 要 Cassandra，多年基本没维护，不建议。
- 其它（GetStream / Social+ / Weavy …）全是商业 SaaS。
- 行业共识（10K–1M 用户量级）：**单 Postgres + 后台任务（BullMQ）扇出**即可。正常用户 fan-out-on-write 到每用户 feed 表 / Redis sorted set；大 V（>50 万粉）fan-out-on-read，混合。

**结论**：social 自己在 Postgres 写（约 5 张表：`social_post` / `post_comment` / `post_like`〔唯一约束〕/ `follow` / `block` / `report`）。MVP 直接 **fan-out-on-read**（查关注列表的帖子合并排序），feed 延迟成问题了再上 BullMQ 扇出 + Redis。social 帖子跟 Stopwatch 的训练 / 计划强绑，本来也没现成的。

来源：
- OpenIM 文档 https://docs.openim.io/ ・ LICENSE https://github.com/openimsdk/open-im-server/blob/main/LICENSE
- 社交流架构 https://getstream.io/blog/build-a-social-media-app/ ・ https://www.calibreos.com/learn/hld-news-feed

## 10. 首期最小闭环（建议 MVP 边界）

避免摊子铺太大。首个可用版本 = **登录 → 填问卷出计划 → 跟练打卡 → check-in 调整 → 多设备同步**：
`auth-phone` + `auth-wechat` + `profiles` + `plans` + `workouts` + `sync` + `notifications`(最简)。
社交 / 聊天 / 饮食识别 / 附近的人 / 同类对标软提示 —— 都是第二批。

---

## 11. 资源约束下的架构修订（2026-08-31）

**服务器实况**：阿里云 1 核 2 线程 / 2.5GHz / **2GB 内存** / 40GB 磁盘。原架构文档假设的多服务拓扑（NestJS + Python + Postgres + Redis + Kafka/RabbitMQ + MinIO + OpenIM + Prometheus/Grafana）在这台机器上**跑不起来**。

### 11.1 这台机器能装什么

2GB 内存共租（api + db + redis 同机）的现实预算：

| 组件 | 常驻内存 | 说明 |
|---|---|---|
| OS + dockerd | 200–350MB | |
| PostgreSQL（调过参） | 250–350MB | `shared_buffers=192MB` / `work_mem=4MB` / `max_connections=20` / `effective_cache_size=512MB` |
| Redis | 20–40MB | `maxmemory 128mb` + `allkeys-lru` |
| NestJS `apps/api`（限堆） | 250–380MB | `NODE_OPTIONS=--max-old-space-size=384`，单实例，`mem_limit: 512m` |
| **合计基线** | **~750MB–1.1GB** | 留 ~900MB–1.3GB 给负载峰值 + 页缓存 |

**能扛**：MVP / 软启动，粗估几十到几百日活做核心闭环。
**扛不住**：真实增长前必须升配（**建议 2c4g，进一步 4c8g**）。这台不是长期生产机。

### 11.2 装不了的东西（从原方案里砍掉 / 延后）

| 原计划 | 结论 |
|---|---|
| **OpenIM**（聊天）| ❌ 不可行。自带 MongoDB + Kafka + Redis + MinIO，光 Kafka 就要 1GB+。聊天先延后，或退到「NestJS 里最小 1:1 私信」（§9.15 B 路） |
| **Kafka / RabbitMQ** | ❌ 不上。异步任务 = BullMQ 跑在现有 Redis 上 |
| 独立 `worker` 进程 | ❌ 合并。BullMQ worker **在 api 进程内跑**（`@nestjs/bullmq` 同进程消费）。CPU 密集型任务（图片处理）真拖慢了再拆 |
| **MinIO / SeaweedFS** 自托管对象存储 | ❌ 不上。媒体存 **阿里云 OSS**（已定，`media` 模块 driver 就绪）|
| **Prometheus + Grafana + Loki** | ❌ 不上（这套 300MB+）。监控 = 阿里云云监控（agent 轻）+ 结构化日志落文件 + 日志轮转。要看板等升配 |
| Elasticsearch | ❌ 不上。搜索用 Postgres 全文 / `pg_trgm` |
| **独立 Python `services/planner`** | 🟡 **延后部署**。Dart 引擎在端上出计划，MVP 服务端不生成计划；同类对标要每桶 ≥20 人才有输出，冷启动期是空的；服务端复现（`/v1/plan/replay`）也非 MVP。等真需要了再上这个服务（~120–180MB，本身很轻）|
| `postgis/postgis` 镜像 | 🟡 换回 `postgres:16-alpine`。「附近的人」是 v1.1/v2，等做那个功能再换 postgis（省镜像体积 + 一点内存）|
| PgBouncer | 🟡 先不上（少一个进程）。Node pg pool `max: 10` 够用，连接数爬上来再加 |

### 11.3 MVP 实际运行拓扑

```
阿里云 1c2t/2G/40G ── docker compose：
  postgres:16-alpine   （调过参 + 命名卷）
  redis:7-alpine       （maxmemory 128mb）
  api                  （NestJS，单实例，BullMQ worker 同进程，堆限 384MB）
外部：
  阿里云 OSS            （媒体）
  阿里云 / 腾讯云 SMS    （短信 OTP）
  APNs / FCM / 厂商推送  （通知，待接）
  阿里云云监控 + 日志     （监控）
```

Python planner / 社交流扇出 worker / OpenIM —— 升配后再进拓扑。

### 11.4 磁盘（40GB）

- OS ~6–8GB，Docker 镜像 ~1GB（都用 alpine + 多阶段构建），Postgres 数据增长要盯。
- Docker 日志驱动锁 `json-file` `max-size=10m max-file=3`（否则日志能把盘写满）。
- DB 备份：**每晚 `pg_dump` 直传 OSS**，不留本地。
- 盘用到 70% 告警。用户上传全走 OSS，不落本地盘。

### 11.5 已写代码要不要改？

**不用**。已合并的 7 个模块（auth / profiles / plans / workouts / sync / media / notifications）都是轻量 CRUD + Postgres，没有内存大户。本次修订改的是**部署拓扑 + 不再往上加什么**，不是重写代码。
唯一动代码的点：BullMQ 接进 api 进程（做异步任务时）、`dev.compose` / 新 `prod.compose` 换 postgres-alpine + 去掉 planner。

### 11.6 建议

1. 这台机器定位为 **MVP / 内测机**，上线前升 2c4g（或直接用阿里云 RDS 托管 Postgres 把 DB 内存压力挪走）。
2. 阶段 5：`social` 照常自写（Postgres，轻）；`chat` **延后**到升配后接 OpenIM，或本期只做「文字 1:1 私信」最小实现（socket.io + redis-adapter，同 api 进程）。
3. planner 服务先不部署，`plans` 模块存快照的能力已经够 MVP。
