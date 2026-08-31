# Stopwatch 计划引擎服务（`backend/services/planner`）

对应《Stopwatch 后端架构与 Docker 部署方案》§2.2 的「Python FastAPI + Pydantic，独立 Docker 镜像」。
职责：服务端标准版本计划复现（后续）+ **同类对标（统计聚合）**。

> 这个服务**不做账号 / 训练历史 / 多设备同步** —— 那些是 NestJS `apps/api` + 训练数据组的活（§1、§8）。
> 同类对标只吃**匿名化**的 check-in 结果，`device_id` 只做「同设备同阶段」去重（sha256 + 服务端盐），不可反推。

## 接口

| 方法 | 路径 | 说明 |
|---|---|---|
| `POST` | `/v1/cohort/submit` | 客户端上报一条匿名 check-in 结果 |
| `GET`  | `/v1/cohort/benchmark` | 查同类 N 周典型轨迹（p25/p50/p75） |
| `GET`  | `/health` | 健康检查 |

### `POST /v1/cohort/submit`
```json
{
  "device_id": "<稳定设备标识>",
  "weeks_elapsed": 8,
  "planner_version": "1.8",
  "profile": {"sex": "M", "age": 27, "bmi": 23.5,
              "level": "beginner", "goal": "hypertrophy",
              "equipment": ["dumbbell"]},
  "metrics": {"bench_e1rm_pct": 12.0, "squat_e1rm_pct": 9.5,
              "hinge_e1rm_pct": 11.0, "row_e1rm_pct": 8.0,
              "perf_median_pct": 10.2, "bodyweight_pct": 1.8,
              "adherence_pct": 80.0, "completed_cycles": 1}
}
```
`metrics` 各项由客户端引擎算好（`progress_tracker` 的证据），可空。
同一 `device_hash` + `weeks_band` 只保留最新一条。

### `GET /v1/cohort/benchmark`
Query：`sex, age, bmi, level, goal, weeks_elapsed, equipment`（多个 `equipment` 重复传）
```json
{
  "available": true,
  "cohort_key": "M|25-29|22-25|beginner|hypertrophy|gym|8w",
  "cohort_size": 240,
  "widened": false,
  "metrics": {"bench_e1rm_pct": {"n": 240, "p25": 6.0, "p50": 12.0, "p75": 18.0}, ...}
}
```
桶里 <20 人（`PLANNER_MIN_COHORT`）时按 `bmi_band → age_band → equipment_tier` 逐步放宽；
还不够 → `{"available": false}`。

**软提示**：客户端拿到 benchmark 后用 `cohort_compare()`（`fitness-planner/engine/cohort_compare.py` / `flutter/lib/planner/cohort_compare.dart`）把「你 +8% vs 同类 p50 +12%」翻成一句话。

## 本地跑

```bash
cd backend/services/planner
python -m venv .venv && . .venv/bin/activate
pip install -r requirements.txt
PLANNER_DATABASE_URL=sqlite:///./dev.db uvicorn app.main:app --reload --port 8080
pytest                    # 纯逻辑 + API 冒烟
```

## Docker（服务器上）

```bash
# 装 Docker（Ubuntu/Debian）
curl -fsSL https://get.docker.com | sh

# 配 .env
cat > backend/deploy/compose/.env <<EOF
PLANNER_DEVICE_SALT=$(openssl rand -hex 32)
PLANNER_DB_PASSWORD=$(openssl rand -hex 16)
PLANNER_PORT=8080
EOF

docker compose -f backend/deploy/compose/planner.compose.yaml up -d
```
镜像启动时自动 `alembic upgrade head`。Postgres 数据在 named volume `planner_pgdata`，
生产务必配自动备份 / 用托管 Postgres。

## 迁移

```bash
PLANNER_DATABASE_URL=... alembic revision --autogenerate -m "xxx"
PLANNER_DATABASE_URL=... alembic upgrade head
```
