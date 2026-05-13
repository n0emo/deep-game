from __future__ import annotations
from dataclasses import dataclass
from enum import Enum, auto
from lastshot.assets import Assets
from lastshot.events import (
    ButtonPressedEvent,
    ChangeAudioVolumeEvent,
    ExitEvent,
    StartGameEvent,
)
from .scene import Scene
from lastshot.ui import (
    text_centered,
    button_centered,
    slider_centered,
    background_texture_centered,
)
import pyray as rl
from typing import override

TEXT_SIZE = 32
BUTTON_SIZE = rl.Vector2(300, 50)
SLIDER_SIZE = rl.Vector2(300, 50)
PANEL_SIZE = rl.Vector2(550, 400)


class _Screen(Enum):
    HOME = auto()
    SETTINGS = auto()


@dataclass
class AudioSettings:
    master_volume: float
    music_volume: float
    sfx_volume: float


class MenuScene(Scene):
    __bg_texture: rl.Texture
    __audio_settings: AudioSettings
    __screen: _Screen

    def __init__(self, assets: Assets, audio_settings: AudioSettings) -> None:
        super().__init__(assets)
        self.__bg_texture = assets.sprites.bg_main_menu
        self.__audio_settings = audio_settings
        self.__screen = _Screen.HOME

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
            background_texture_centered(self.__bg_texture)
            text_centered("Deep Game", 64, rl.Vector2(0, -300))
            self.__draw_panel(PANEL_SIZE)

            match self.__screen:
                case _Screen.HOME:
                    self.__draw_home()
                case _Screen.SETTINGS:
                    self.__draw_settings()
        finally:
            rl.gui_set_style(
                rl.GuiControl.DEFAULT, rl.GuiDefaultProperty.TEXT_SIZE, old_size
            )

    def __draw_panel(self, size: rl.Vector2) -> None:
        rec = rl.Rectangle(
            (rl.get_screen_width() - size.x) * 0.5,
            (rl.get_screen_height() - size.y) * 0.5,
            size.x,
            size.y,
        )
        rl.draw_rectangle_rounded(rec, 0.2, 3, rl.fade(rl.BEIGE, 0.8))

    def __draw_home(self) -> None:
        if button_centered("Start Game", BUTTON_SIZE, rl.Vector2(0, -60)):
            self.dispatch(ButtonPressedEvent())
            self.dispatch(StartGameEvent())

        if button_centered("Settings", BUTTON_SIZE, rl.Vector2(0, 0)):
            self.dispatch(ButtonPressedEvent())
            self.__screen = _Screen.SETTINGS

        if button_centered("Exit", BUTTON_SIZE, rl.Vector2(0, 60)):
            self.dispatch(ButtonPressedEvent())
            self.dispatch(ExitEvent())

    def __draw_settings(self) -> None:
        _, self.__audio_settings.master_volume = slider_centered(
            "Master",
            self.__audio_settings.master_volume,
            SLIDER_SIZE,
            rl.Vector2(0, -90),
        )
        _, self.__audio_settings.music_volume = slider_centered(
            "Music", self.__audio_settings.music_volume, SLIDER_SIZE, rl.Vector2(0, -30)
        )
        _, self.__audio_settings.sfx_volume = slider_centered(
            "SFX", self.__audio_settings.sfx_volume, SLIDER_SIZE, rl.Vector2(0, 30)
        )

        self.dispatch(
            ChangeAudioVolumeEvent(
                master_volume=self.__audio_settings.master_volume / 100,
                music_volume=self.__audio_settings.music_volume / 100,
                sfx_volume=self.__audio_settings.sfx_volume / 100,
            )
        )

        if button_centered("Back", BUTTON_SIZE, rl.Vector2(0, 90)):
            self.dispatch(ButtonPressedEvent())
            self.__screen = _Screen.HOME
