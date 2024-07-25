import enum


class JobType(enum.Enum):
    """
    An enumeration representing the possible reduction states.
    """
    RERUN = "RERUN"
    SIMPLE = "SIMPLE"
    AUTOREDUCTION = "AUTOREDUCTION"
