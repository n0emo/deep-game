from __future__ import annotations
from lastshot.assets import Assets
from lastshot.audio import AudioSystem
from lastshot.player_stats import PlayerStats
from .scene import Scene
from lastshot.events import (
    Event,
    FightBeginEvent,
    FightEnemyTurnEvent,
    FightPlayerAttackMeleeEvent,
    FightPlayerAttackRangeEvent,
    FightPlayerDeflectEvent,
    FightPlayerParryEvent,
    FightWinEvent,
    InputGoEvent,
    LoseEvent,
    PlayerStoppedEvent,
    TransitionEvent,
    EndTransitioningEvent,
    WinEvent,
)
from .fight import FightScene
from .overworld import OverworldScene
from .transitioning import TransitioningScene
from lastshot.tilemap import TileMap
from lastshot.objects import ObjectEnemy
import random
from typing import override


class WorldScene(Scene):
    __tilemaps: list[TileMap]
    __current_tilemap: int
    __stats: PlayerStats
    __active: Scene
    __overworld: OverworldScene | None
    __audio_system: AudioSystem

    def __init__(self, assets: Assets, audio: AudioSystem) -> None:
        super().__init__(assets)
        self.__tilemaps = [
            TileMap.load(assets.tilemap_level_1),
            TileMap.load(assets.tilemap_level_2),
        ]
        self.__audio_system = audio
        self.__current_tilemap = -1
        self.__stats = PlayerStats()
        self.__active = self.__make_transitioning()
        self.__overworld = None
        for event_type in [
            InputGoEvent,
            FightPlayerParryEvent,
            FightPlayerDeflectEvent,
            FightPlayerAttackMeleeEvent,
            FightPlayerAttackRangeEvent,
        ]:
            self.subscribe(event_type, self.handle_event)

    @override
    def update(self) -> None:
        if self.__current_tilemap >= len(self.__tilemaps):
            self.dispatch(WinEvent())
            return
        self.__active.update()
        # drain child events up to self
        # (requires Scene.poll() or shared dispatcher — see note below)

    @override
    def draw(self) -> None:
        self.__active.draw()

    def handle_event(self, event: Event) -> None:
        # forward to active child first
        if hasattr(self.__active, "handle_event"):
            self.__active.handle_event(event)

        match event:
            case FightBeginEvent():
                scene = self.__make_fight(event.enemy)
                scene.subscribe(FightWinEvent, lambda e: self.handle_event(e))
                scene.subscribe(FightEnemyTurnEvent, lambda e: self.handle_event(e))
                self.__active = scene

            case FightWinEvent():
                if random.random() < 0.5:
                    self.__stats.melee_damage += 2
                else:
                    self.__stats.range_damage += 2
                self.__stats.shield += 1
                assert self.__overworld is not None
                self.__active = self.__overworld

            case TransitionEvent():
                self.__active = self.__make_transitioning()

            case EndTransitioningEvent():
                self.__current_tilemap += 1
                if self.__current_tilemap < len(self.__tilemaps):
                    self.__overworld = self.__make_overworld()
                    self.__active = self.__overworld

    def __make_transitioning(self) -> TransitioningScene:
        scene = TransitioningScene(self.assets)
        scene.subscribe(EndTransitioningEvent, lambda e: self.handle_event(e))
        self.__audio_system.subscribe_all(scene)
        return scene

    def __make_overworld(self) -> OverworldScene:
        tilemap = self.__tilemaps[self.__current_tilemap]
        scene = OverworldScene(self.assets, tilemap, self.__current_tilemap + 1)
        scene.subscribe(FightBeginEvent, lambda e: self.handle_event(e))
        scene.subscribe(TransitionEvent, lambda e: self.handle_event(e))
        scene.subscribe(WinEvent, lambda e: self.dispatch(e))
        scene.subscribe(PlayerStoppedEvent, scene.handle_event)
        scene.subscribe(InputGoEvent, scene.handle_event)
        self.__audio_system.subscribe_all(scene)
        return scene

    def __make_fight(self, enemy: ObjectEnemy) -> FightScene:
        scene = FightScene(self.assets, self.__stats, enemy)
        scene.subscribe(FightWinEvent, lambda e: self.handle_event(e))
        scene.subscribe(LoseEvent, lambda e: self.dispatch(e))
        self.__audio_system.subscribe_all(scene)
        return scene
