from sys import platform
from typing import TYPE_CHECKING

if platform in ("win32", "darwin", "linux") or TYPE_CHECKING:
    from .desktop import run as run
elif platform == "brython":
    from .web import run as run
else:
    raise Exception(f"Platform '{platform}' is not supported")
