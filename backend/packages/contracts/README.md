# `packages/contracts` — 前后端契约

## `openapi.json`

`apps/api` 全部 HTTP 接口的 OpenAPI **3.1** spec。给 Flutter 前端生成 client / 对接看。

重新生成（改了 controller / DTO 后跑）：

```bash
cd backend/apps/api
npm run openapi:export      # → ../../packages/contracts/openapi.json
```

headless 生成，不连 DB / Redis（NestJS preview 模式）。需要 `.env`（`cp env-example-relational .env`）。

**Flutter 侧**：用 `openapi-generator` / `swagger_dart_code_generator` 之类从这个文件出 model + api client。

### 约定

- 所有业务接口前缀 `/api/v1`，URI 版本化。
- 认证：`Authorization: Bearer <token>`（`/api/v1/auth/*` 拿 token）。
- **游标分页**：列表返回 `{ data: [...], nextCursor: string | null }`（schema 名 `XxxCursorPage`）。
  下一页把 `nextCursor` 原样回传到 `?cursor=`。`nextCursor === null` = 没有更多。
- 时间统一 UTC ISO8601。
- 领域实体主键是 UUID 字符串；`user` 相关 id 是整数（见 ADAPTATION_PLAN §9.9）。

## `sync.md`

离线增量同步协议 v1（`/api/v1/sync/batch` + `/api/v1/sync/changes`）。
Dart / TS 客户端都照它实现 Outbox + cursor 拉取。

## MVP 闭环相关接口速查

| 场景 | 接口 |
|---|---|
| 登录 | `POST /api/v1/auth/phone/send-code` → `/auth/phone/login`（或 `/auth/wechat/login`） |
| 当前用户 | `GET /api/v1/auth/me` |
| 训练画像 | `GET` / `PUT /api/v1/profile/me` |
| 保存端上引擎出的计划 | `POST /api/v1/plans`（带 `plannerVersion` + `inputSnapshot` + `planJson`） |
| 当前计划 / 版本历史 | `GET /api/v1/plans/current` / `/plans/current/versions` |
| 记录训练 | `POST /api/v1/workouts/sessions` → `/sessions/:id/sets` → `PATCH /sessions/:id`（完成） |
| 训练历史 / 日历 | `GET /api/v1/workouts/sessions?from=&to=&status=&planVersionId=` |
| 称重 / 围度 | `PUT /api/v1/body-logs`（按日期 upsert）/ `GET /api/v1/body-logs?from=&to=` |
| 多设备同步 | `POST /api/v1/sync/batch` + `GET /api/v1/sync/changes?cursor=`（见 sync.md） |
| 通知 | `GET /api/v1/notifications` / `/unread-count` / `POST /notifications/read` / `POST /notifications/devices` |
| 社交 | `GET /api/v1/social/feed` / `POST /social/posts` / `POST /social/follow/:userId` … |
