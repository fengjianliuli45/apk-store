# backend/

按《Stopwatch 后端架构与 Docker 部署方案》的目录约定。**目前只落了 `services/planner`**。

```
backend/
  services/
    planner/          ← Python FastAPI：同类对标（统计聚合）+ 服务端计划复现（后续）
  deploy/
    compose/
      planner.compose.yaml   ← planner 服务 + 独立 Postgres
```

还没做（属 NestJS `apps/api` + 各业务组，见架构文档 §1 / §8）：
`apps/api`（账号 / 用户资料 / 计划版本 / 训练记录 / 离线同步 / 社区 / 消息 / 通知）、
`apps/worker`、`packages/contracts`、`packages/database`。

## 账号体系（架构文档要的：手机号 + 微信 + Google）

不在这个服务里 —— 归 `apps/api`。同类对标只吃匿名 check-in 结果，`apps/api` 上线后由它
在服务端把用户结果脱敏后转投 `services/planner`（或客户端直接带匿名 device 标识上报）。
