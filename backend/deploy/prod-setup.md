# 小机器生产 / 内测部署备忘

目标机：阿里云 1 核 2 线程 / 2.5GHz / 2GB 内存 / 40GB 磁盘。
架构取舍见 `backend/apps/api/ADAPTATION_PLAN.md` §11。拓扑见 `deploy/compose/prod.compose.yaml`。

## 一次性准备

### 1. 加 swap（必做，2GB 内存没 swap 会被 OOM kill）

```bash
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
sudo sysctl vm.swappiness=10
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.d/99-swap.conf
```

### 2. Docker 全局日志上限（否则日志写满盘）

`/etc/docker/daemon.json`：

```json
{ "log-driver": "json-file", "log-opts": { "max-size": "10m", "max-file": "3" } }
```

`sudo systemctl restart docker`

### 3. `.env`

`cp backend/apps/api/env-example-relational backend/apps/api/.env`，至少改：
`DATABASE_USERNAME` / `DATABASE_PASSWORD` / `AUTH_JWT_SECRET` / `AUTH_REFRESH_SECRET` /
`AUTH_FORGOT_SECRET` / `AUTH_CONFIRM_EMAIL_SECRET`（都 `openssl rand -hex 32`）、
`MEDIA_DRIVER=s3` + `MEDIA_S3_*`（阿里云 OSS）、`SMS_DRIVER=aliyun` + `SMS_ALIYUN_*`。

## 起 / 更新

```bash
cd backend/deploy/compose
docker compose -f prod.compose.yaml --env-file ../../apps/api/.env up -d --build
# 迁移（首次 + 每次 schema 变更）
docker compose -f prod.compose.yaml exec api npm run migration:run
```

## 每晚备份（cron）

```bash
# crontab -e  →  30 3 * * *  /opt/stopwatch/backup.sh
#!/usr/bin/env bash
set -euo pipefail
TS=$(date +%F)
docker compose -f /opt/stopwatch/backend/deploy/compose/prod.compose.yaml exec -T postgres \
  pg_dump -U "$DATABASE_USERNAME" "$DATABASE_NAME" | gzip > /tmp/db-$TS.sql.gz
# 传 OSS，删本地
ossutil cp /tmp/db-$TS.sql.gz oss://<bucket>/backups/db-$TS.sql.gz
rm /tmp/db-$TS.sql.gz
```

## 盯什么

- `docker stats`：api 常驻应 < 400MB；postgres < 400MB。持续爆 → 升配。
- `df -h`：盘 > 70% 告警。
- 阿里云云监控：CPU / 内存 / 盘 / 带宽，设阈值短信。

## 什么时候升配

- api 或 postgres 频繁触 `mem_limit` 被重启；
- `docker stats` 长期内存 > 85%；
- 要上 Python planner / 聊天服务 / 社交流扇出 worker；
→ 先 **2c4g**，或把 Postgres 挪到阿里云 RDS（DB 内存压力最大）。
