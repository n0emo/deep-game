from typing import List, Dict
from dataclasses import dataclass, field
from engine import Rectangle, Texture


@dataclass
class Tile:
    type: str = ""
    frame: Rectangle = field(default_factory=Rectangle)
    texture: Texture | None = None
    flipped_horizontally: bool = False
    flipped_vertically: bool = False
    flipped_diagonally: bool = False
    rotated_hex120: bool = False


ObjectValue = str | int


@dataclass
class Object:
    width: int
    height: int
    x: int
    y: int
    id: int
    name: str
    opacity: float
    point: bool
    rotation: int
    type: str
    visible: bool
    properties: Dict[str, ObjectValue]


@dataclass
class LayerBase:
    id: int
    x: int
    y: int
    name: str
    layer_class: str
    opacity: float
    visible: bool


@dataclass
class TileLayer(LayerBase):
    width: int
    height: int
    tiles: List[Tile]

    def get_tile(self, x: int, y: int) -> Tile:
        return self.tiles[self.width * y + x]


@dataclass
class ObjectLayer(LayerBase):
    objects: List[Object]


Layer = TileLayer | ObjectLayer


@dataclass
class Tilemap:
    compressionlevel: int
    height: int
    width: int
    infinite: bool
    nextlayerid: int
    nextobjectid: int
    orientation: str
    renderorder: str
    tiledversion: str
    tileheight: int
    tilewidth: int
    type: str
    version: str
    layers: List[Layer]
