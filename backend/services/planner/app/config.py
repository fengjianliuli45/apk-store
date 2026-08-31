from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="PLANNER_", env_file=".env", extra="ignore")

    # sqlite 供本地 / 测试；生产走 compose 里的 postgres
    database_url: str = "sqlite:///./planner.db"
    # 上报去重窗口：同一设备同一 weeks_band 只保留最新一条
    dedup_by_device: bool = True
    # k-匿名下限（也在 cohort.MIN_COHORT，改这里需同步）
    min_cohort: int = 20
    planner_version: str = "1.8"
    cors_origins: list[str] = ["*"]


@lru_cache
def get_settings() -> Settings:
    return Settings()
