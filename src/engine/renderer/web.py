from __future__ import annotations
from typing import TYPE_CHECKING, override
from .base import Color, Rectangle, WHITE, Vector2
from engine.texture import Texture
import math
from . import base


if TYPE_CHECKING:
    from browser.html import CANVAS, CanvasRenderingContext2D


class Renderer(base.Renderer):
    __canvas: CANVAS
    __ctx: CanvasRenderingContext2D

    def __init__(self, canvas: CANVAS) -> None:
        self.__canvas = canvas
        self.__ctx = canvas.getContext("2d")
        self.__set_image_smoothing(False)

    @property
    def canvas(self) -> CANVAS:
        return self.__canvas

    @property
    def ctx(self) -> CanvasRenderingContext2D:
        return self.__ctx

    @override
    def resize(self, width: int, height: int) -> None:
        self.__canvas.setAttribute("width", width)
        self.__canvas.setAttribute("height", height)
        self.__set_image_smoothing(False)

    @override
    def clear(self, color: Color) -> None:
        rect = Rectangle(0, 0, self.canvas.width, self.canvas.height)
        self.fill_rect(rect, color)

    @override
    def fill_rect(self, rect: Rectangle, color: Color) -> None:
        self.__fill_style(color)
        self.ctx.fillRect(rect.x, rect.y, rect.w, rect.h)

    @override
    def texture(self, texture: Texture, x: int, y: int, tint: Color = WHITE) -> None:
        width, height = texture.image.naturalWidth, texture.image.naturalHeight

        self.texture_pro(
            texture,
            source=Rectangle(0, 0, width, height),
            dest=Rectangle(x, y, width, height),
            origin=Vector2(0, 0),
            rotation=0,
            tint=tint,
        )

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
        flip_x = source.w < 0
        flip_y = source.h < 0
        src_x = source.x
        src_y = source.y
        src_w = abs(source.w)
        src_h = abs(source.h)

        ctx = self.__ctx
        ctx.save()

        ctx.translate(dest.x, dest.y)
        if rotation != 0:
            ctx.rotate(rotation * math.pi / 180)
        ctx.translate(-origin.x, -origin.y)

        if flip_x or flip_y:
            ctx.translate(dest.w if flip_x else 0, dest.h if flip_y else 0)
            ctx.scale(-1 if flip_x else 1, -1 if flip_y else 1)

        is_opaque = tint.r == 255 and tint.g == 255 and tint.b == 255 and tint.a == 255

        if is_opaque:
            ctx.drawImage(
                texture.image, src_x, src_y, src_w, src_h, 0, 0, dest.w, dest.h
            )
        else:
            if tint.a != 255:
                ctx.globalAlpha = tint.a / 255

            if tint.r == 255 and tint.g == 255 and tint.b == 255:
                ctx.drawImage(
                    texture.image, src_x, src_y, src_w, src_h, 0, 0, dest.w, dest.h
                )
            else:
                off_ctx = texture.offscreen
                off_ctx.clearRect(0, 0, dest.w, dest.h)

                # Resize offscreen canvas if needed
                if off_ctx.canvas.width != dest.w or off_ctx.canvas.height != dest.h:
                    off_ctx.canvas.width = dest.w
                    off_ctx.canvas.height = dest.h

                off_ctx.globalCompositeOperation = "source-over"
                off_ctx.drawImage(
                    texture.image, src_x, src_y, src_w, src_h, 0, 0, dest.w, dest.h
                )

                off_ctx.globalCompositeOperation = "multiply"
                off_ctx.fillStyle = f"rgb({tint.r}, {tint.g}, {tint.b})"
                off_ctx.fillRect(0, 0, dest.w, dest.h)

                off_ctx.globalCompositeOperation = "destination-in"
                off_ctx.drawImage(
                    texture.image, src_x, src_y, src_w, src_h, 0, 0, dest.w, dest.h
                )

                ctx.drawImage(off_ctx.canvas, 0, 0)

        ctx.restore()

    def __fill_style(self, color: Color) -> None:
        self.ctx.fillStyle = f"rgba({color.r}, {color.g}, {color.b}, {color.a})"

    def __set_image_smoothing(self, smoothing: bool) -> None:
        self.__ctx.webkitImageSmoothingEnabled = False
        self.__ctx.mozImageSmoothingEnabled = False
        self.__ctx.imageSmoothingEnabled = False
