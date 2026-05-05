from dataclasses import dataclass
from pathlib import Path
from typing import List
from engine import Rectangle, Texture


@dataclass
class TilesetTile:
    type: str
    frame: Rectangle


@dataclass
class Tileset:
    texture: Texture
    name: str
    columns: int
    image: Path
    imageheight: int
    imagewidth: int
    margin: int
    spacing: int
    type: str
    version: str
    tilecount: int
    tiledversion: str
    tileheight: int
    tilewidth: int
    tiles: List[TilesetTile]

    def get_tile(self, id: int) -> TilesetTile:
        return self.tiles[id]
