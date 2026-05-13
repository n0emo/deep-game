from __future__ import annotations
from dataclasses import dataclass
from typing import TYPE_CHECKING
import pyray as rl
from tiled import Tilemap, TileLayer, ObjectLayer, Tile
from lastshot.objects import Object, ObjectSpawnpoint, object_make

if TYPE_CHECKING:
    pass

TILE_SIZE = 16
ENABLE_DEBUG = False


@dataclass
class TileMap:
    tilemap: Tilemap
    base_layer: TileLayer
    prop_layer: TileLayer
    obj_layer: ObjectLayer
    objects: dict[int, Object]
    spawnpoint: Object

    @staticmethod
    def load(tilemap: Tilemap) -> TileMap:
        base_layer = _find_tile_layer(tilemap, "base")
        prop_layer = _find_tile_layer(tilemap, "prop")
        obj_layer = _find_obj_layer(tilemap, "object")

        objects: dict[int, Object] = {}
        spawnpoint: Object | None = None

        for obj in obj_layer.objects:
            objects[obj.id] = object_make(obj)
            if isinstance(objects[obj.id].properties, ObjectSpawnpoint):
                spawnpoint = objects[obj.id]

        if spawnpoint is None:
            raise ValueError("No spawnpoint found in tilemap")

        return TileMap(
            tilemap=tilemap,
            base_layer=base_layer,
            prop_layer=prop_layer,
            obj_layer=obj_layer,
            objects=objects,
            spawnpoint=spawnpoint,
        )

    @property
    def width(self) -> int:
        return self.tilemap.width

    @property
    def height(self) -> int:
        return self.tilemap.height

    def draw(self, offset: rl.Vector2) -> None:
        _draw_tile_layer(self, self.base_layer, offset)
        _draw_tile_layer(self, self.prop_layer, offset)
        if ENABLE_DEBUG:
            _draw_objects(self, offset)

    def tile_passable(self, tile: tuple[int, int]) -> bool:
        x, y = tile
        if not (0 <= x < self.width and 0 <= y < self.height):
            return False
        t = _layer_get_tile(self.base_layer, x, y)
        return t.type == "terrain"

    def collides_with_object(self, rect: rl.Rectangle) -> Object | None:
        for obj in self.objects.values():
            obj_rect = rl.Rectangle(obj.x, obj.y, obj.width, obj.height)
            if rl.check_collision_recs(rect, obj_rect):
                return obj
        return None

    def delete_object(self, id: int) -> None:
        self.objects.pop(id, None)


def _draw_tile_layer(m: TileMap, layer: TileLayer, offset: rl.Vector2) -> None:
    for x in range(m.width):
        for y in range(m.height):
            dest = rl.Rectangle(
                offset.x + x * TILE_SIZE,
                offset.y + y * TILE_SIZE,
                TILE_SIZE,
                TILE_SIZE,
            )
            tile = _layer_get_tile(layer, x, y)
            if tile.texture is not None:
                rl.draw_texture_pro(
                    tile.texture, tile.frame, dest, rl.Vector2(0, 0), 0.0, rl.WHITE
                )


def _draw_objects(m: TileMap, offset: rl.Vector2) -> None:
    for obj in m.objects.values():
        dest = rl.Rectangle(
            offset.x + obj.x,
            offset.y + obj.y,
            obj.width + 1,
            obj.height + 1,
        )
        rl.draw_rectangle_lines_ex(dest, 1.0, rl.RED)


def _find_tile_layer(tilemap: Tilemap, cls: str) -> TileLayer:
    for layer in tilemap.layers:
        if isinstance(layer, TileLayer) and layer.layer_class == cls:
            return layer
    raise ValueError(f"Tile layer '{cls}' not found in tilemap")


def _find_obj_layer(tilemap: Tilemap, cls: str) -> ObjectLayer:
    for layer in tilemap.layers:
        if isinstance(layer, ObjectLayer) and layer.layer_class == cls:
            return layer
    raise ValueError(f"Object layer '{cls}' not found in tilemap")


def _layer_get_tile(layer: TileLayer, x: int, y: int) -> Tile:
    return layer.get_tile(x, y)
