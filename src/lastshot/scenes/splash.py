from __future__ import annotations
from lastshot.assets import Assets
from .scene import Scene
from lastshot.events import MenuEvent
import pyray as rl
from typing import override

SPLASH_DURATION = 0.1


class SplashScene(Scene):
    __timer: float

    def __init__(self, assets: Assets) -> None:
        super().__init__(assets)
        self.__timer = 0.0

    @override
    def update(self) -> None:
        self.__timer += rl.get_frame_time()
        if self.__timer >= SPLASH_DURATION:
            self.dispatch(MenuEvent())

    @override
    def draw(self) -> None:
        rl.clear_background(rl.BLACK)
