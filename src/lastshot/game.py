from typing import Optional
from lastshot.assets import Assets
from lastshot.events import ExitEvent, LoseEvent, MenuEvent, StartGameEvent, WinEvent
from lastshot.input import InputSystem
from lastshot.scenes import DeadScene
from lastshot.scenes import (
    AudioSettings,
    MenuScene,
)
import pyray as rl

from lastshot.scenes import SplashScene
from lastshot.scenes.world import WorldScene
from .scenes import Scene, WinScene
from .audio import AudioSystem


class Game:
    __assets: Assets
    __current_scene: Optional[Scene]
    __next_scene: Optional[Scene]
    __audio: AudioSystem
    __input: InputSystem
    __running: bool

    def __init__(self) -> None:
        self.__assets = Assets.load()
        self.__current_scene = None
        self.__next_scene = None
        self.__audio = AudioSystem(self.__assets.audio)
        self.__input = InputSystem()
        self.__running = True

        self.__queue_splash_transition()

    def frame(self) -> None:
        self.__audio.update()

        if self.__next_scene is not None:
            self.__current_scene = self.__next_scene
            self.__next_scene = None

        assert self.__current_scene is not None

        self.__input.update(self.__current_scene)

        rl.clear_background(rl.SKYBLUE)
        self.__current_scene.update()
        self.__current_scene.draw()

    @property
    def running(self) -> bool:
        return self.__running and not rl.window_should_close()

    def __queue_transition(self, scene: Scene) -> None:
        if self.__next_scene is not None:
            raise ValueError("Already transitioning")

        self.__audio.subscribe_all(scene)
        self.__next_scene = scene

    def __queue_splash_transition(self) -> None:
        s = SplashScene(self.__assets)
        s.subscribe(MenuEvent, self.__on_menu)
        self.__queue_transition(s)

    def __queue_menu_scene_transition(self) -> None:
        s = MenuScene(
            self.__assets,
            AudioSettings(
                master_volume=self.__audio.master_volume * 100,
                music_volume=self.__audio.music_volume * 100,
                sfx_volume=self.__audio.sfx_volume * 100,
            ),
        )
        s.subscribe(ExitEvent, self.__on_menu_exit)
        s.subscribe(StartGameEvent, self.__on_game_start)
        self.__queue_transition(s)

    def __queue_win_scene_transition(self) -> None:
        s = WinScene(self.__assets)
        s.subscribe(MenuEvent, self.__on_menu)
        self.__queue_transition(s)

    def __queue_dead_scene_transition(self) -> None:
        s = DeadScene(self.__assets)
        s.subscribe(MenuEvent, self.__on_menu)
        self.__queue_transition(s)

    def __on_menu(self, _: MenuEvent) -> None:
        self.__queue_menu_scene_transition()

    def __on_game_start(self, _: StartGameEvent) -> None:
        s = WorldScene(self.__assets, self.__audio)
        s.subscribe(WinEvent, self.__on_win)
        s.subscribe(LoseEvent, self.__on_lose)
        self.__queue_transition(s)

    def __on_win(self, _: WinEvent) -> None:
        self.__queue_win_scene_transition()

    def __on_lose(self, _: LoseEvent) -> None:
        self.__queue_dead_scene_transition()

    def __on_menu_exit(self, _: ExitEvent) -> None:
        self.__running = False
