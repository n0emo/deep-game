from pathlib import Path
from typing import override
from engine import Application, Context, Texture, Color, Vector2, Rectangle
from tiled import Loader, TileLayer

TILESIZE = 16


class Game(Application):
    def __init__(self) -> None:
        self.texture = Texture.load(
            Path("assets", "sprites", "background-main-menu.png")
        )
        self.loader = Loader()
        self.level_1 = self.loader.load_tilemap(
            Path("assets", "tilemaps", "level-1.tmj")
        )
        self.level_2 = self.loader.load_tilemap(
            Path("assets", "tilemaps", "level-2.tmj")
        )

    @override
    def frame(self, ctx: Context) -> None:
        self.renderer.clear(Color(255, 255, 255, 255))
        assert isinstance(self.level_1.layers[0], TileLayer)
        assert isinstance(self.level_1.layers[1], TileLayer)
        self.draw_layer(self.level_1.layers[0])
        self.draw_layer(self.level_1.layers[1])

    def draw_layer(self, layer: TileLayer) -> None:
        for x in range(0, layer.width):
            for y in range(0, layer.height):
                tile = layer.get_tile(x, y)
                if tile.texture is None:
                    continue
                dest = Rectangle(x * TILESIZE, y * TILESIZE, TILESIZE, TILESIZE)
                self.renderer.texture_pro(
                    tile.texture, tile.frame, dest, Vector2(0, 0), 0
                )
