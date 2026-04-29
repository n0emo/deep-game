import sys

if sys.platform == "brython":
    from .web import Texture as Texture
elif sys.platform in ("win32", "darwin", "linux"):
    from .desktop import Texture as Texture
else:
    raise Exception(f"Platform '{sys.platform}' is not supported")
