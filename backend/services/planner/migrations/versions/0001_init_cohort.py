"""init cohort_submissions

Revision ID: 0001_init_cohort
Revises:
Create Date: 2026-08-30
"""
import sqlalchemy as sa
from alembic import op

revision = "0001_init_cohort"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "cohort_submissions",
        sa.Column("id", sa.String(length=36), primary_key=True),
        sa.Column("device_hash", sa.String(length=64), nullable=False),
        sa.Column("submitted_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("planner_version", sa.String(length=16), nullable=False, server_default=""),
        sa.Column("sex", sa.String(length=1), nullable=False),
        sa.Column("age_band", sa.String(length=8), nullable=False),
        sa.Column("bmi_band", sa.String(length=10), nullable=False),
        sa.Column("level", sa.String(length=16), nullable=False),
        sa.Column("goal", sa.String(length=20), nullable=False),
        sa.Column("equipment_tier", sa.String(length=8), nullable=False),
        sa.Column("weeks_band", sa.String(length=8), nullable=False),
        sa.Column("weeks_elapsed", sa.Float(), nullable=False, server_default="0"),
        sa.Column("bench_e1rm_pct", sa.Float(), nullable=True),
        sa.Column("squat_e1rm_pct", sa.Float(), nullable=True),
        sa.Column("hinge_e1rm_pct", sa.Float(), nullable=True),
        sa.Column("row_e1rm_pct", sa.Float(), nullable=True),
        sa.Column("perf_median_pct", sa.Float(), nullable=True),
        sa.Column("bodyweight_pct", sa.Float(), nullable=True),
        sa.Column("adherence_pct", sa.Float(), nullable=True),
        sa.Column("completed_cycles", sa.Integer(), nullable=True),
        sa.UniqueConstraint("device_hash", "weeks_band", name="uq_device_weeksband"),
    )
    op.create_index("ix_cohort_submissions_device_hash", "cohort_submissions", ["device_hash"])
    op.create_index(
        "ix_cohort_lookup", "cohort_submissions",
        ["sex", "level", "goal", "weeks_band", "age_band", "bmi_band", "equipment_tier"],
    )


def downgrade() -> None:
    op.drop_table("cohort_submissions")
