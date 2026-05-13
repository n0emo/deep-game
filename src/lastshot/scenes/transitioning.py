from __future__ import annotations
from lastshot.assets import Assets
from .scene import Scene
from lastshot.events import EndTransitioningEvent
from lastshot.easings import ease_in_expo
import pyray as rl
from typing import override

SCALE = 5


class TransitioningScene(Scene):
    __player: rl.Texture
    __x: float
    __y: float
    __elapsed: float
    __duration: float
    __end_y: float
    __finished: bool

    def __init__(self, assets: Assets) -> None:
        super().__init__(assets)
        player = assets.sprites.player_transitioning
        self.__player = player
        self.__x = (rl.get_screen_width() - player.width * SCALE) / 2
        self.__end_y = rl.get_screen_height() - player.height * SCALE
        self.__y = 0.0
        self.__elapsed = 0.0
        self.__duration = 2.0
        self.__finished = False

    @override
    def update(self) -> None:
        if self.__finished:
            return
        self.__elapsed += rl.get_frame_time()
        progress = min(self.__elapsed / self.__duration, 1.0)
        self.__y = ease_in_expo(0.0, self.__end_y, progress)
        if progress >= 1.0:
            self.__finished = True
            self.dispatch(EndTransitioningEvent())

    @override
    def draw(self) -> None:
        rl.clear_background(rl.BLACK)
        rl.draw_texture_ex(
            self.__player, rl.Vector2(self.__x, self.__y), 0.0, float(SCALE), rl.WHITE
        )
