from __future__ import annotations
from lastshot.assets import Assets
from lastshot.events import MenuEvent
from .scene import Scene
from lastshot.ui import text_centered, button_centered, background_texture_centered
import pyray as rl
from typing import override

TEXT_SIZE = 32


class WinScene(Scene):
    texture: rl.Texture

    def __init__(self, assets: Assets) -> None:
        super().__init__(assets)
        self.texture = assets.sprites.bg_win

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

        rl.clear_background(rl.get_color(0x231D29FF))
        background_texture_centered(self.texture)

        size = rl.Vector2(720, 300)
        rec = rl.Rectangle(
            (rl.get_screen_width() - size.x) * 0.5,
            (rl.get_screen_height() - size.y) * 0.5,
            size.x,
            size.y,
        )
        rl.draw_rectangle_rounded(rec, 0.2, 3, rl.fade(rl.BROWN, 0.6))
        text_centered(
            "You saved the world!\nThanks for playing.", 64, rl.Vector2(0, -70)
        )

        if button_centered("Back to main menu", rl.Vector2(500, 50), rl.Vector2(0, 70)):
            self.__go_to_menu()

        rl.gui_set_style(
            rl.GuiControl.DEFAULT, rl.GuiDefaultProperty.TEXT_SIZE, old_size
        )

    def __go_to_menu(self) -> None:
        self.dispatch(MenuEvent())
