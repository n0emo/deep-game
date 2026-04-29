from sys import platform
from typing import TYPE_CHECKING

if platform in ("win32", "darwin", "linux") or TYPE_CHECKING:
    from .desktop import Renderer as Renderer
elif platform == "brython":
    from .web import Renderer as Renderer
else:
    raise Exception(f"Platform '{platform}' is not supported")
