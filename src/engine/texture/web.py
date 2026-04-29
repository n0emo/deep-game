from typing import TYPE_CHECKING, override
from pathlib import Path
from browser.html import IMG
from browser import window

if TYPE_CHECKING:
    from browser.html import CanvasRenderingContext2D

from .base import BaseTexture


class Texture(BaseTexture):
    __image: IMG
    __offscreen: CanvasRenderingContext2D

    def __init__(self, image: IMG) -> None:
        self.__image = image
        offscreen = window.OffscreenCanvas.new(100, 100)
        self.__offscreen = offscreen.getContext("2d")

    @property
    def image(self) -> IMG:
        return self.__image

    @property
    def offscreen(self) -> CanvasRenderingContext2D:
        return self.__offscreen

    @classmethod
    @override
    def load(cls, path: Path) -> "Texture":
        image = IMG(src=str(path))
        return Texture(image)

    @override
    def unload(self) -> None:
        pass
