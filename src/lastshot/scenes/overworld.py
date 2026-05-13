from __future__ import annotations
from dataclasses import dataclass
from lastshot.assets import Assets
from .scene import Scene
from lastshot.events import (
    Event,
    FightEncounterEvent,
    FightBeginEvent,
    InputGoEvent,
    PlayerMovingEvent,
    PlayerStoppedEvent,
    TransitionEvent,
)
from lastshot.direction import Direction
from lastshot.tilemap import TileMap, TILE_SIZE
from lastshot.objects import ObjectSpawnpoint, ObjectTransition, ObjectEnemy, Object
from lastshot.animation import Animation, animation_frame_from_atlas
from atlas import Atlas
import pyray as rl
import random
from typing import override

CAMERA_LERP = 0.08
PLAYER_SPEED = 7.0
PLAYER_NON_IDLE_TIME = 0.1
ENCOUNTER_TIME = 2.5
ENCOUNTER_ZOOM_FACTOR = 12.0
ENCOUNTER_ROTATION_FACTOR = 15.0
RANDOM_ENCOUNTER_PROBABILITY = 0.01

BACKGROUND_COLOR = rl.get_color(0x29211DFF)


@dataclass
class _PlayerIdle:
    pass


@dataclass
class _PlayerMoving:
    start: rl.Vector2
    end: rl.Vector2
    interpolator: float = 0.0


@dataclass
class _EncounterState:
    event: FightEncounterEvent
    time: float = 0.0


@dataclass
class _OverworldPlayer:
    tile: tuple[int, int]
    pos: rl.Vector2
    direction: Direction
    state: _PlayerIdle | _PlayerMoving
    idle_time: float
    animation_current: Animation
    animations_idle: dict[Direction, Animation]
    animations_moving: dict[Direction, Animation]
    started_moving: bool = False


def _make_player(atlas: Atlas, tile: tuple[int, int]) -> _OverworldPlayer:
    def anim(prefix: str) -> Animation:
        return Animation(
            texture=atlas.texture,
            frames=[
                animation_frame_from_atlas(atlas, f"{prefix}-{i}") for i in range(4)
            ],
        )

    animations_idle = {
        Direction.UP: anim("player-idle-back"),
        Direction.DOWN: anim("player-idle-front"),
        Direction.LEFT: anim("player-idle-left"),
        Direction.RIGHT: anim("player-idle-right"),
    }
    animations_moving = {
        Direction.UP: anim("player-move-back"),
        Direction.DOWN: anim("player-move-front"),
        Direction.LEFT: anim("player-move-left"),
        Direction.RIGHT: anim("player-move-right"),
    }
    return _OverworldPlayer(
        tile=tile,
        pos=rl.Vector2(tile[0] * TILE_SIZE, tile[1] * TILE_SIZE),
        direction=Direction.DOWN,
        state=_PlayerIdle(),
        idle_time=0.0,
        animation_current=animations_idle[Direction.DOWN],
        animations_idle=animations_idle,
        animations_moving=animations_moving,
    )


def _make_random_encounter_pool(scale: int) -> list[Object]:
    enemies = [
        ("servitor", 120),
        ("melee", 100),
        ("range", 90),
        ("gear", 82),
        ("turret", 70),
        ("drone", 60),
        ("range", 50),
        ("range", 40),
        ("melee", 30),
        ("range", 20),
        ("melee", 10),
    ]
    return [
        Object(
            id=-1,
            x=0,
            y=0,
            width=0,
            height=0,
            properties=ObjectEnemy(hp=hp * scale, enemy_name=name),
        )
        for name, hp in enemies
    ]


class OverworldScene(Scene):
    __tilemap: TileMap
    __player: _OverworldPlayer
    __camera: rl.Camera2D
    __encountering: bool
    __encounter_state: _EncounterState | None
    __random_encounter_pool: list[Object]
    __random_encounter: bool

    def __init__(self, assets: Assets, tilemap: TileMap, scale: int) -> None:
        super().__init__(assets)
        sp = tilemap.spawnpoint
        tile = (int(sp.x) // TILE_SIZE, int(sp.y) // TILE_SIZE)
        self.__tilemap = tilemap
        self.__player = _make_player(assets.sprites.player, tile)
        self.__camera = rl.Camera2D(
            rl.Vector2(rl.get_screen_width() * 0.5, rl.get_screen_height() * 0.5),
            rl.Vector2(0, 0),
            0.0,
            6.0,
        )
        self.__encountering = False
        self.__encounter_state = None
        self.__random_encounter_pool = _make_random_encounter_pool(scale)
        self.__random_encounter = False
        self.subscribe(PlayerStoppedEvent, self.handle_event)
        self.subscribe(InputGoEvent, self.handle_event)

    def update(self) -> None:
        self.__update_player()
        self.__update_camera()

        player_rect = rl.Rectangle(
            self.__player.pos.x, self.__player.pos.y, TILE_SIZE, TILE_SIZE
        )
        obj = self.__tilemap.collides_with_object(player_rect)
        if obj is not None:
            match obj.properties:
                case ObjectSpawnpoint():
                    pass
                case ObjectTransition():
                    self.dispatch(TransitionEvent())
                case ObjectEnemy() as enemy:
                    if not self.__encountering:  # guard against repeated dispatches
                        self.__tilemap.delete_object(obj.id)
                        self.__encountering = True
                        self.__encounter_state = _EncounterState(
                            event=FightEncounterEvent(obj=obj, enemy=enemy)
                        )
                        self.dispatch(FightEncounterEvent(obj=obj, enemy=enemy))

        if self.__random_encounter and not self.__encountering:
            if self.__random_encounter_pool:
                enemy_obj = self.__random_encounter_pool.pop()
                props = enemy_obj.properties
                assert isinstance(props, ObjectEnemy)
                self.__encountering = True
                self.__encounter_state = _EncounterState(
                    event=FightEncounterEvent(obj=enemy_obj, enemy=props)
                )
                self.dispatch(FightEncounterEvent(obj=enemy_obj, enemy=props))
            self.__random_encounter = False

        if self.__encountering and self.__encounter_state is not None:
            self.__encounter_state.time += rl.get_frame_time()
            if self.__encounter_state.time >= ENCOUNTER_TIME:
                e = self.__encounter_state.event
                self.dispatch(FightBeginEvent(enemy=e.enemy, obj=e.obj))
                self.__encounter_state = None
                self.__encountering = False

    @override
    def draw(self) -> None:
        rl.clear_background(BACKGROUND_COLOR)
        rl.begin_mode_2d(self.__camera)
        self.__tilemap.draw(rl.Vector2(0, 0))
        self.__player.animation_current.draw(self.__player.pos)
        rl.end_mode_2d()

    def handle_event(self, event: Event) -> None:
        match event:
            case InputGoEvent():
                if self.__encountering:
                    return
                p = self.__player
                dv = event.direction.to_vec_i32()
                next_tile = (p.tile[0] + dv[0], p.tile[1] + dv[1])
                if self.__tilemap.tile_passable(next_tile):
                    if isinstance(p.state, _PlayerIdle):
                        self.__start_moving(event.direction)
                else:
                    p.direction = event.direction
            case PlayerStoppedEvent():
                if random.random() < RANDOM_ENCOUNTER_PROBABILITY:
                    self.__random_encounter = True

    def __update_player(self) -> None:
        p = self.__player
        if p.started_moving:
            p.started_moving = False
            self.dispatch(PlayerMovingEvent())

        p.animation_current.update()
        p.pos = rl.Vector2(p.tile[0] * TILE_SIZE, p.tile[1] * TILE_SIZE)

        match p.state:
            case _PlayerIdle():
                p.idle_time += rl.get_frame_time()
                if p.idle_time > PLAYER_NON_IDLE_TIME:
                    p.animation_current = p.animations_idle[p.direction]
            case _PlayerMoving() as state:
                p.idle_time = 0.0
                state.interpolator += rl.get_frame_time() * PLAYER_SPEED
                t = state.interpolator
                p.pos = rl.Vector2(
                    state.start.x + (state.end.x - state.start.x) * t,
                    state.start.y + (state.end.y - state.start.y) * t,
                )
                if state.interpolator >= 1.0:
                    self.dispatch(PlayerStoppedEvent(direction=p.direction))
                    p.state = _PlayerIdle()

    def __start_moving(self, direction: Direction) -> None:
        p = self.__player
        p.started_moving = True
        dv = direction.to_vec_i32()
        old_tile = p.tile
        new_tile = (old_tile[0] + dv[0], old_tile[1] + dv[1])
        p.tile = new_tile
        p.animation_current = p.animations_moving[direction]
        p.direction = direction
        p.state = _PlayerMoving(
            start=rl.Vector2(old_tile[0] * TILE_SIZE, old_tile[1] * TILE_SIZE),
            end=rl.Vector2(new_tile[0] * TILE_SIZE, new_tile[1] * TILE_SIZE),
        )

    def __update_camera(self) -> None:
        t = self.__encounter_state.time if self.__encounter_state else 0.0
        self.__camera.zoom = 6.0 + t * ENCOUNTER_ZOOM_FACTOR
        self.__camera.rotation = t * ENCOUNTER_ROTATION_FACTOR
        self.__camera.offset = rl.Vector2(
            rl.get_screen_width() * 0.5,
            rl.get_screen_height() * 0.5,
        )
        target = self.__camera.target
        player = self.__player.pos
        self.__camera.target = rl.Vector2(
            target.x + (player.x - target.x) * CAMERA_LERP,
            target.y + (player.y - target.y) * CAMERA_LERP,
        )
