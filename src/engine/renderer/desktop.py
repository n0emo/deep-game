from typing import override
import pyray
from dataclasses import astuple

from engine.texture import Texture
from .base import WHITE, Color, Rectangle, Vector2
from . import base


class Renderer(base.Renderer):
    @override
    def clear(self, color: Color) -> None:
        pyray.clear_background(astuple(color))

    @override
    def fill_rect(self, rect: Rectangle, color: Color) -> None:
        pyray.draw_rectangle_rec(astuple(rect), astuple(color))

    @override
    def texture(self, texture: Texture, x: int, y: int, tint: Color = WHITE) -> None:
        pyray.draw_texture(texture.texture, x, y, astuple(tint))

    @override
    def texture_pro(
        self,
        texture: Texture,
        source: Rectangle,
        dest: Rectangle,
        origin: Vector2,
        rotation: float,
        tint: Color = WHITE,
    ) -> None:
        pyray.draw_texture_pro(
            texture.texture,
            astuple(source),
            astuple(dest),
            astuple(origin),
            rotation,
            astuple(tint),
        )
