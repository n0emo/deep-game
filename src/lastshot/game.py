from pathlib import Path
from typing import override
from engine import Application, Context, Texture, Vector2, Rectangle, Renderer
from tiled import TileLayer
from abc import ABC, abstractmethod

TILESIZE = 16


class Scene(ABC):
    @abstractmethod
    def draw(self, renderer: Renderer) -> None: ...

    @abstractmethod
    def update(self, dt: float) -> None: ...


class MenuScene(Scene):
    background: Texture

    def __init__(self) -> None:
        self.background = Texture.load(
            Path("assets", "sprites", "background-main-menu.png")
        )

    @override
    def draw(self, renderer: Renderer) -> None:
        renderer.texture(self.background, 0, 0)

    @override
    def update(self, dt: float) -> None:
        pass


class GameScene(Scene):
    pass


class WinScene(Scene):
    pass


class DeadScene(Scene):
    pass


class Game(Application):
    __current_scene: Scene

    def __init__(self) -> None:
        self.__current_scene = MenuScene()

    @override
    def frame(self, ctx: Context) -> None:
        self.__current_scene.update(ctx.dt)
        self.__current_scene.draw(self.renderer)

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
