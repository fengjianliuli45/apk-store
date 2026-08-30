from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .config import get_settings
from .routers import cohort

settings = get_settings()

app = FastAPI(
    title="Stopwatch Planner Service",
    version=settings.planner_version,
    description="服务端计划引擎 + 同类对标（统计聚合）。见 backend/services/planner/README.md",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)

app.include_router(cohort.router)


@app.get("/health")
def health() -> dict:
    return {"status": "ok", "planner_version": settings.planner_version}


@app.on_event("startup")
def _startup() -> None:
    # 生产用 alembic；sqlite（本地/测试）直接建表
    if settings.database_url.startswith("sqlite"):
        from .db import init_db
        init_db()
