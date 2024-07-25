from datetime import datetime

from sqlalchemy import DateTime, Enum, ForeignKey, String
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from db.data_models import JobOwner
from db.data_models.base import Base
from db.data_models.job_type import JobType
from db.data_models.run import Run
from db.data_models.run_job import run_job_junction_table
from db.data_models.script import Script
from db.data_models.state import State


class Job(Base):
    """
    The Job class represents a reduction in the database.
    """

    __tablename__ = "reductions"
    start: Mapped[datetime | None] = mapped_column(DateTime())
    end: Mapped[datetime | None] = mapped_column(DateTime())
    state: Mapped[State] = mapped_column(Enum(State))
    status_message: Mapped[str | None] = mapped_column(String())
    inputs: Mapped[JSONB] = mapped_column(JSONB)
    outputs: Mapped[str | None] = mapped_column(String())
    stacktrace: Mapped[str | None] = mapped_column(String())
    script_id: Mapped[int | None] = mapped_column(ForeignKey("scripts.id"))
    job_type: Mapped[JobType] = mapped_column(Enum(JobType))
    script: Mapped[Script | None] = relationship("Script", lazy="joined")
    runs: Mapped[list[Run]] = relationship(
        secondary=run_job_junction_table,
        back_populates="reductions",
        lazy="subquery",
    )
    owner: Mapped[JobOwner | None] = relationship("Owner", lazy="joined")

    def __repr__(self) -> str:
        return (
            f"Job(id={self.id}, start={self.start}, end={self.end}, state={self.state}, inputs={self.inputs}, "
            f"outputs={self.outputs}, script_id={self.script_id})"
        )
