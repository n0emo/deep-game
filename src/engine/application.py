from abc import ABC, abstractmethod
from dataclasses import dataclass

from engine.renderer import Renderer


@dataclass
class Context:
    dt: float
    elapsed: float


class Application(ABC):
    __renderer: Renderer

    @property
    def renderer(self) -> Renderer:
        return self.__renderer

    @renderer.setter
    def renderer(self, value: Renderer) -> None:
        self.__renderer = value

    @abstractmethod
    def frame(self, ctx: Context) -> None: ...
