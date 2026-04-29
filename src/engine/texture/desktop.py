from typing import override
from pathlib import Path
import pyray

from .base import BaseTexture


class Texture(BaseTexture):
    __texture: pyray.Texture

    def __init__(self, texture: pyray.Texture) -> None:
        self.__texture = texture

    @property
    def texture(self) -> pyray.Texture:
        return self.__texture

    @classmethod
    @override
    def load(cls, path: Path) -> "Texture":
        texture = pyray.load_texture(str(path))
        return Texture(texture)

    @override
    def unload(self) -> None:
        pyray.unload_texture(self.__texture)
