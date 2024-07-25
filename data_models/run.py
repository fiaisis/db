from typing import Self

from sqlalchemy import Column, DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, relationship

from db.data_models import JobOwner
from db.data_models.base import Base
from db.data_models.instrument import Instrument
from db.data_models.job import Job


class Run(Base):
    """
    The Run table's declarative declaration
    """

    __tablename__ = "runs"
    id = Column(Integer, primary_key=True, autoincrement=True)
    filename = Column(String)
    instrument_id = Column(Integer, ForeignKey("instruments.id"))
    title = Column(String)
    users = Column(String)
    run_start = Column(DateTime)
    run_end = Column(DateTime)
    good_frames = Column(Integer)
    raw_frames = Column(Integer)
    reductions: Mapped[list[Job]] = relationship("RunReduction", back_populates="run_relationship")
    instrument: Mapped[Instrument] = relationship("Instrument", lazy="joined")
    owner_id = Column(Integer, ForeignKey("job_owners.id"))
    owner: Mapped[JobOwner | None] = relationship("Owner", lazy="joined")

    def __eq__(self, other: Self) -> bool:
        if isinstance(other, Run):
            return (
                self.filename == other.filename
                and self.title == other.title
                and self.instrument_id == other.instrument_id
                and self.users == other.users
                and self.owner.experiment_number == other.owner.experiment_number
                and self.run_start == other.run_start
                and self.run_end == other.run_end
                and self.good_frames == other.good_frames
                and self.raw_frames == other.raw_frames
            )
        return False

    def __repr__(self) -> str:
        return (
            f"<Run(id={self.id}, filename={self.filename}, instrument_id={self.instrument_id}, title={self.title},"
            f" users={self.users}, experiment_number={self.experiment_number}, run_start={self.run_start},"
            f" run_end={self.run_end}, good_frames={self.good_frames}, raw_frames={self.raw_frames})>"
        )