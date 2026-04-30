from pathlib import Path
from .tilemap import Tilemap
from .tileset import Tileset


class Loader:
    def load_tileset(self, path: Path) -> None:
        raise NotImplementedError()

    def load_tilemap(self, path: Path) -> None:
        raise NotImplementedError()

    def get_tilemap(self, name: str) -> Tilemap:
        raise NotImplementedError()

    def get_tileset(self, name: str) -> Tileset:
        raise NotImplementedError()

    def unload_tilset(self, name: str) -> None:
        raise NotImplementedError()

    def unload_tilemap(self, name: str) -> None:
        raise NotImplementedError()

    def unload_all(self) -> None:
        raise NotImplementedError()
