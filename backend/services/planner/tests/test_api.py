"""API 冒烟测试（需要 fastapi / sqlalchemy / pytest；跑：pip install -r requirements.txt && pytest）。"""
import importlib.util
import os
import sys
import unittest
from pathlib import Path

if any(importlib.util.find_spec(m) is None for m in ("pytest", "fastapi", "sqlalchemy")):
    raise unittest.SkipTest("fastapi / pytest 未安装，跳过 API 测试（纯逻辑见 test_cohort_logic）")

import pytest  # noqa: E402

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
os.environ["PLANNER_DATABASE_URL"] = "sqlite:///./test_planner.db"

from fastapi.testclient import TestClient  # noqa: E402


@pytest.fixture()
def client(tmp_path):
    dbfile = tmp_path / "t.db"
    os.environ["PLANNER_DATABASE_URL"] = f"sqlite:///{dbfile}"
    # 重新加载依赖 settings 的模块
    for m in list(sys.modules):
        if m.startswith("app"):
            del sys.modules[m]
    from app.main import app
    with TestClient(app) as c:
        yield c


def _submit(client, device, age=27, bmi=23.5, bench=None):
    r = client.post("/v1/cohort/submit", json={
        "device_id": device, "weeks_elapsed": 8, "planner_version": "1.8",
        "profile": {"sex": "M", "age": age, "bmi": bmi, "level": "beginner",
                    "goal": "hypertrophy", "equipment": ["dumbbell"]},
        "metrics": {"bench_e1rm_pct": bench if bench is not None else 12.0,
                    "adherence_pct": 80.0},
    })
    assert r.status_code == 200, r.text
    return r


def test_health(client):
    assert client.get("/health").json()["status"] == "ok"


def test_submit_dedup(client):
    r = _submit(client, "device-aaaaaa")
    assert r.status_code == 200
    assert r.json()["cohort_key"] == "M|25-29|22-25|beginner|hypertrophy|gym|8w"
    # 同设备同 weeks_band 再传 → 覆盖不新增
    _submit(client, "device-aaaaaa", bench=20.0)
    b = client.get("/v1/cohort/benchmark", params={
        "sex": "M", "age": 27, "bmi": 23.5, "level": "beginner",
        "goal": "hypertrophy", "weeks_elapsed": 8, "equipment": ["dumbbell"]})
    # 只有 1 人 → 不够 k 匿名
    assert b.json()["available"] is False


def test_benchmark_k_anonymity_and_percentiles(client):
    for i in range(25):
        _submit(client, f"dev-{i:03d}", bench=float(i))   # 0..24
    b = client.get("/v1/cohort/benchmark", params={
        "sex": "M", "age": 27, "bmi": 23.5, "level": "beginner",
        "goal": "hypertrophy", "weeks_elapsed": 8, "equipment": ["dumbbell"]}).json()
    assert b["available"] is True
    assert b["cohort_size"] == 25
    st = b["metrics"]["bench_e1rm_pct"]
    assert st["p50"] == 12.0
    assert st["p25"] == 6.0 and st["p75"] == 18.0


def test_benchmark_widens_when_bmi_bucket_thin(client):
    # 25 人同 cohort 但 bmi 各异 → 精确桶不足，放宽掉 bmi_band 后够
    for i in range(25):
        _submit(client, f"wide-{i:03d}", bmi=18.0 + i * 0.4, bench=float(i))
    b = client.get("/v1/cohort/benchmark", params={
        "sex": "M", "age": 27, "bmi": 23.5, "level": "beginner",
        "goal": "hypertrophy", "weeks_elapsed": 8, "equipment": ["dumbbell"]}).json()
    assert b["available"] is True
    assert b["widened"] is True
