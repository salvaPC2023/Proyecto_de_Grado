from datetime import datetime
import os
import pytz

SHIFT_WINDOWS: dict[int, tuple[int, int]] = {
    1: (23, 7),   # 23:00 – 07:00 (crosses midnight)
    2: (7, 15),   # 07:00 – 15:00
    3: (15, 23),  # 15:00 – 23:00
}

SHIFT_LABELS: dict[int, tuple[str, str]] = {
    1: ("23:00", "07:00"),
    2: ("07:00", "15:00"),
    3: ("15:00", "23:00"),
}


def get_current_shift(dt: datetime) -> int:
    """Return the active shift number (1, 2, or 3) for the given timezone-aware datetime."""
    tz_name = os.environ.get("SERVER_TIMEZONE", "America/La_Paz")
    tz = pytz.timezone(tz_name)
    local_dt = dt.astimezone(tz)
    hour = local_dt.hour

    if hour >= 23 or hour < 7:
        return 1
    if 7 <= hour < 15:
        return 2
    return 3
