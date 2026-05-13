from __future__ import annotations
from lastshot.assets import Assets
from .scene import Scene
from lastshot.events import MenuEvent
from lastshot.ui import text_centered, button_centered, background_texture_centered
import pyray as rl
from typing import override

TEXT_SIZE = 32


class DeadScene(Scene):
    __texture: rl.Texture

    def __init__(self, assets: Assets) -> None:
        super().__init__(assets)
        self.__texture = assets.sprites.bg_dead

    @override
    def update(self) -> None:
        pass

    @override
    def draw(self) -> None:
        old_size = rl.gui_get_style(
            rl.GuiControl.DEFAULT, rl.GuiDefaultProperty.TEXT_SIZE
        )
        rl.gui_set_style(
            rl.GuiControl.DEFAULT, rl.GuiDefaultProperty.TEXT_SIZE, TEXT_SIZE
        )

        try:
            rl.clear_background(rl.get_color(0x231D29FF))
            background_texture_centered(self.__texture, align_top=True)
            text_centered("Game over!", 64, rl.Vector2(0, 0))

            if button_centered("Retry", rl.Vector2(200, 50), rl.Vector2(0, 60)):
                self.dispatch(MenuEvent())
        finally:
            rl.gui_set_style(
                rl.GuiControl.DEFAULT, rl.GuiDefaultProperty.TEXT_SIZE, old_size
            )
