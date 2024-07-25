import enum


class State(enum.Enum):
    """
    An enumeration representing the possible reduction states.
    """

    SUCCESSFUL = "SUCCESSFUL"
    UNSUCCESSFUL = "UNSUCCESSFUL"
    ERROR = "ERROR"
    NOT_STARTED = "NOT_STARTED"
