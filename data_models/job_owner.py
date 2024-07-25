from sqlalchemy import Integer
from sqlalchemy.orm import Mapped, mapped_column

from db.data_models import Base


class JobOwner(Base):
    id: Mapped[int] = mapped_column(Integer(), primary_key=True)
    experiment_number: Mapped[int | None] = mapped_column(Integer(), unique=True)
    user_number: Mapped[int | None] = mapped_column(Integer(), unique=True)
