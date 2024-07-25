from typing import Self

from sqlalchemy import (  # type: ignore[attr-defined]
    Column,
    Integer,
    String,
)

from db.data_models.base import Base


class Instrument(Base):  # type: ignore[valid-type, misc]
    """
    The Instrument Table's declarative declaration
    """

    __tablename__ = "instruments"
    id = Column(Integer, primary_key=True)
    instrument_name = Column(String, unique=True)
    latest_run = Column(String)

    def __eq__(self, other: Self) -> bool:
        if isinstance(other, Instrument):
            return bool(self.instrument_name == other.instrument_name and self.latest_run == other.latest_run)
        return False

    def __repr__(self) -> str:
        return f"<Instrument(id={self.id}, instrument_name={self.instrument_name}, latest_run={self.latest_run})>"
