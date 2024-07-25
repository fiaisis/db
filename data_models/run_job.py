from sqlalchemy import Column, ForeignKey, Table

from db.data_models.base import Base

run_job_junction_table = Table(
    "runs_reductions",
    Base.metadata,
    Column("run_id", ForeignKey("runs.id")),
    Column("job_id", ForeignKey("reductions.id")),
)
