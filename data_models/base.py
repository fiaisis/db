from sqlalchemy import inspect
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class Base(DeclarativeBase):
    """
    Base class for SQLAlchemy ORM models. It includes a primary key `id` attribute, and defines equality as deep
    equality.
    """

    id: Mapped[int] = mapped_column(primary_key=True)

    def __eq__(self, other: object) -> bool:
        """
        Check if two instances of Base are equal by comparing the values of their column attributes.

        :param other: The other instance of Base to compare with.
        :return: True if the instances are equal, False otherwise.
        """
        if not isinstance(other, Base):
            return False
        # Ignores due to inspect returning Any, includes None, by default
        return {attr.key: getattr(self, attr.key) for attr in inspect(self).mapper.column_attrs} == {
            attr.key: getattr(other, attr.key) for attr in inspect(other).mapper.column_attrs
        }
