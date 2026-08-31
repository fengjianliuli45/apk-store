# 同步协议 v1（离线增量同步）

> 对齐 `backend/apps/api/ADAPTATION_PLAN.md` §9.1。
> 实现：`backend/apps/api/src/sync/` + `src/sync-events/`。
> Dart / TS 客户端都按本文实现。

## 模型

- 服务端为每个用户维护一条**单调递增的变更序列** `serverSeq`（从 1 开始，`sync_event` 表）。
- 每条 `sync_event` = `{ serverSeq, entityType, entityId, op, payload, clientEventId, occurredAt }`。
- 客户端保存一个 **Outbox**：本地发生的写操作先入队，联网后批量上传。
- 客户端保存一个 **syncCursor**：已经拉到的最大 `serverSeq`。

## 幂等

- 每条上传事件带一个客户端生成的 `clientEventId`（UUID，全局唯一）。
- 服务端按 `(userId, clientEventId)` 去重（DB 唯一约束）。重放 → 返回原来的 `serverSeq`，不重复应用。
- **所有写操作都要带 `clientEventId`**，不是可选。

## 冲突

- **训练记录（workout_session / workout_set）= 事件追加**，几乎不 update；服务端按事件幂等去重即可，不需要冲突解决。
- **可变资料（profile）**：v1 用**后写胜**（服务端接收顺序）。v2 若出现多设备并发改同一字段的实际问题，再引入字段级版本号 / lamport clock（§9.1）。
- 删除保留 tombstone：`op = 'delete'` 的事件会一直在变更流里，客户端拉到即删本地。

## 端点

### `POST /api/v1/sync/batch`

上传 Outbox。请求：

```json
{
  "events": [
    {
      "clientEventId": "a1b2c3...",
      "entityType": "workout_session",
      "op": "create",
      "payload": { "sessionType": "strength", "planVersionId": "..." },
      "occurredAt": "2026-09-01T10:00:00Z"
    }
  ]
}
```

- `entityType` ∈ `workout_session` | `workout_set` | `profile`（后续扩展）
- `op` ∈ `create` | `update` | `delete`
- `payload` 的形状 = 对应领域端点的 body：
  - `workout_session` `create` → `POST /workouts/sessions` 的 body
  - `workout_session` `update` → `{ id, ...PATCH body }`
  - `workout_set` `create` → `{ sessionId, sets: [...] }`
  - `workout_set` `update` → `{ id, ...PATCH body }`
  - `workout_set` `delete` → `{ id }`
  - `profile` `create`/`update` → `PUT /profile/me` 的 body
- 一批最多 500 条，按数组顺序逐条应用。

响应：

```json
{
  "results": [
    { "clientEventId": "a1b2c3...", "status": "applied", "serverSeq": 42 },
    { "clientEventId": "d4e5f6...", "status": "duplicate", "serverSeq": 40 },
    { "clientEventId": "g7h8i9...", "status": "rejected", "error": "session notFound" }
  ],
  "syncCursor": 42
}
```

- `applied`：已应用并登记，`serverSeq` 是它的序号。
- `duplicate`：`clientEventId` 之前见过，`serverSeq` 是原来那条。客户端可以从 Outbox 移除。
- `rejected`：这条没应用（如引用了不存在 / 越权的实体）。客户端要么修正要么丢弃，**不阻塞后面的条目**。
- 客户端处理完 batch 后，应立即调 `changes` 拉回自己刚上传的 + 其它设备的变更，再更新本地 `syncCursor`。

### `GET /api/v1/sync/changes?cursor=<serverSeq>&limit=<n>`

拉增量。返回 `serverSeq > cursor` 的事件，按 `serverSeq` 升序。

```json
{
  "events": [
    { "id": "...", "serverSeq": 41, "entityType": "profile", "entityId": "...", "op": "update", "payload": { ... }, "occurredAt": "...", "createdAt": "..." }
  ],
  "nextCursor": 41,
  "hasMore": true
}
```

- `limit` 默认 200，最大 500。
- `hasMore = true` → 用 `nextCursor` 再拉一页。
- 客户端把每条事件的 `payload` 投影到本地库，然后把本地 `syncCursor` 更新为 `nextCursor`。

## 客户端流程

```
上线：
  1. POST /sync/batch  { Outbox 里所有事件 }
  2. 处理 results：applied/duplicate → 出队；rejected → 记录/丢弃
  3. GET /sync/changes?cursor=<本地 syncCursor>  循环直到 hasMore=false
  4. 每页事件投影到本地库，syncCursor = nextCursor

离线：
  写操作 → 立即改本地库 + 追加到 Outbox（带新生成的 clientEventId）
```

## v1 已知限制（→ v2）

- 变更流是 best-effort 登记：领域写成功但登记失败时，该变更暂不进流（会打日志）。变更流可从领域表重建。**要做**：把登记放进和领域写同一个事务。
- `serverSeq` 用 `MAX+1 + 唯一约束重试` 分配，高并发下有重试成本。**要做**：换成每用户计数器行 `UPDATE ... RETURNING`。
- 没有 `plan` / `body_log` 的同步（plan 走 `POST /plans` 自己的版本化；body_log 还没建表）。
- 没有服务端主动推送（WebSocket）——客户端靠轮询 `changes`。
- profile 冲突是后写胜，没有字段级合并。
