from sqlalchemy import String
from sqlalchemy.orm import Mapped, mapped_column

from db.data_models import Base


class Script(Base):
    """
    The Script class represents a script in the database.
    """

    __tablename__ = "scripts"
    script: Mapped[str] = mapped_column(String())
    sha: Mapped[str | None] = mapped_column(String())
    script_hash: Mapped[str] = mapped_column(String())

    def __repr__(self) -> str:
        return f"Script(id={self.id}, sha='{self.sha}', script_hash='{self.script_hash}', value='{self.script}')"
