from abc import ABC, abstractmethod
from ..texture import Texture
from engine.color import Color, WHITE
from engine.rectangle import Rectangle
from engine.vector2 import Vector2


class Renderer(ABC):
    @abstractmethod
    def clear(self, color: Color) -> None: ...

    @abstractmethod
    def fill_rect(self, rect: Rectangle, color: Color) -> None: ...

    @abstractmethod
    def texture(
        self, texture: Texture, x: int, y: int, tint: Color = WHITE
    ) -> None: ...

    @abstractmethod
    def texture_pro(
        self,
        texture: Texture,
        source: Rectangle,
        dest: Rectangle,
        origin: Vector2,
        rotation: float,
        tint: Color = WHITE,
    ) -> None: ...
