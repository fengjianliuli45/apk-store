# Project instructions — Stopwatch `apps/api`

基于 `brocoders/nestjs-boilerplate`（基线见 `STOPWATCH.md`），**已裁剪为 PostgreSQL only**
（去掉 Mongoose / document 持久化 / all-db 生成器 / Facebook 登录）。改造方案见 `ADAPTATION_PLAN.md`。

## 加实体 / 属性

用 `generate` skill（`.claude/skills/generate/SKILL.md`）里的 **relational** 生成器
（`npm run generate:resource:relational`、`npm run add:property:to-relational`），
它会把 entity / DTO / module / migration 一起生成。不要手写 entity。
document / all-db 生成器已删，不要用。

## Stopwatch 约定（见 ADAPTATION_PLAN §5 / §9）

- 主键用 **UUIDv7**（`src/common/id/uuid.ts` 的 `newId()`），不用自增 int。
  生成器出来的 entity 记得把 `@PrimaryGeneratedColumn()` 换成 `@PrimaryColumn('uuid')` + `newId()`。
- 列表端点用 **游标分页**（`src/common/pagination/cursor.ts`），禁 deep OFFSET。
- 写端点默认走 `IdempotencyInterceptor`（`src/common/idempotency/`）。
- 跨模块不直接改别的模块的表，走服务接口 / 领域事件。
- 时间统一 UTC，软删除保留 tombstone（离线同步要）。

## 校验

`npm run build` + `npx jest src/common` 必须过。改了实体跑 `npm run migration:generate`。
