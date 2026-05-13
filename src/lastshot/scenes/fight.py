from __future__ import annotations
from dataclasses import dataclass
from enum import Enum, auto
from lastshot.assets import Assets
from lastshot.easings import ease_in_back
from lastshot.sprite import Sprite
from .scene import Scene

from lastshot.events import (
    Event,
    FightPlayerAttackMeleeEvent,
    FightPlayerAttackRangeEvent,
    FightPlayerParryEvent,
    FightPlayerDeflectEvent,
    FightPlayerTurnEvent,
    FightPlayerTakeHitEvent,
    FightPlayerGetHurtEvent,
    FightEnemyTurnEvent,
    FightEnemyAttackMeleeEvent,
    FightEnemyAttackRangedEvent,
    FightEnemyTakeHitEvent,
    FightEnemyDeadEvent,
    FightParrySuccessEvent,
    FightDeflectSuccessEvent,
    FightWinEvent,
    LoseEvent,
    FightEnemyWarnPleaseEvent,
)
from lastshot.animation import Animation
from lastshot.player_stats import PlayerStats
from lastshot.objects import ObjectEnemy
import pyray as rl
import random
from typing import override

SPRITE_SCALE = 4
UI_HEIGHT = 250
FIGHT_LINE = UI_HEIGHT + 200
BUTTON_SIZE = rl.Vector2(300, 50)
PADDING = 40
BUTTON_GAP = 10
GUYS_PADDING = 100
GUYS_LIMIT = 50
PROJECTILE_SPEED = 2.0
PROJECTILE_LIMIT = 10
ENEMY_READY_TIME = 1.5
ENEMY_WARN_TIME = 1.0
ENEMY_ATTACK_VELOCITY = 0.5
PARRY_OFFSET = 150
PARRY_WINDOW_SIZE = 0.15
PARRY_BOUND_HEIGHT = 100
PARRY_LINE_THICKNESS = 10
WIN_JINGLE_TIME = 2.7


class _FightState(Enum):
    PLAYER_TURN = auto()
    PLAYER_ATTACKING_MELEE = auto()
    PLAYER_ATTACKING_RANGE = auto()
    PLAYER_TAKING_HIT = auto()
    ENEMY_TURN = auto()
    ENEMY_ATTACKING_MELEE = auto()
    ENEMY_ATTACKING_RANGE = auto()
    ENEMY_TAKING_HIT = auto()
    WIN_JINGLE = auto()


class _ParryState(Enum):
    NOT_YET_TRIED = auto()
    SUCCESSFUL_PARRY = auto()
    SUCCESSFUL_DEFLECT = auto()
    UNSUCCESSFUL = auto()


@dataclass
class _PendingMelee:
    damage: int


@dataclass
class _PendingRanged:
    damage: int


@dataclass
class _FightPlayer:
    stats: PlayerStats
    projectile: Sprite
    pos_interpolator: float
    parry_state: _ParryState
    animation_idle: Animation
    animation_attack_melee: Animation
    animation_attack_range: Animation
    animation_current: Animation | None = None

    @property
    def hp(self) -> int:
        return self.stats.hp

    @hp.setter
    def hp(self, v: int) -> None:
        self.stats.hp = v

    @property
    def shield(self) -> int:
        return self.stats.shield

    @shield.setter
    def shield(self, v: int) -> None:
        self.stats.shield = v

    @property
    def melee_damage(self) -> int:
        return self.stats.melee_damage

    @property
    def range_damage(self) -> int:
        return self.stats.range_damage


@dataclass
class _FightEnemy:
    hp: int
    max_hp: int
    name: str
    melee_attack_probability: float
    melee_damage: int
    range_damage: int
    melee_damage_reduction: float
    range_damage_reduction: float
    pos_interpolator: float
    ready_time: float
    warned: bool
    animation_idle: Animation
    animation_attack_melee: Animation
    animation_attack_ranged: Animation
    projectile: Sprite | None
    pending: _PendingMelee | _PendingRanged | None = None
    animation_current: Animation | None = None


def _make_enemy(assets: Assets, hp: int, name: str) -> _FightEnemy:
    a = assets.animations
    s = assets.sprites
    configs = {
        "melee": dict(
            melee_damage_reduction=0.1,
            range_damage_reduction=0.1,
            melee_attack_probability=1.0,
            melee_damage=1,
            range_damage=0,
            animation_idle=a.enemy_melee_idle,
            animation_attack_melee=a.enemy_melee_melee_attack,
            animation_attack_ranged=a.enemy_melee_idle,
            projectile=None,
        ),
        "range": dict(
            melee_damage_reduction=0.1,
            range_damage_reduction=0.1,
            melee_attack_probability=0.0,
            melee_damage=0,
            range_damage=1,
            animation_idle=a.enemy_ranger_idle,
            animation_attack_melee=a.enemy_ranger_idle,
            animation_attack_ranged=a.enemy_ranger_ranged_attack,
            projectile=s.projectile_gear,
        ),
        "gear": dict(
            melee_damage_reduction=1.0,
            range_damage_reduction=0.0,
            melee_attack_probability=1.0,
            melee_damage=1,
            range_damage=0,
            animation_idle=a.enemy_gear_idle,
            animation_attack_melee=a.enemy_gear_melee_attack,
            animation_attack_ranged=a.enemy_gear_idle,
            projectile=None,
        ),
        "turret": dict(
            melee_damage_reduction=0.2,
            range_damage_reduction=0.6,
            melee_attack_probability=0.0,
            melee_damage=0,
            range_damage=1,
            animation_idle=a.enemy_turret_idle,
            animation_attack_melee=a.enemy_turret_idle,
            animation_attack_ranged=a.enemy_turret_ranged_attack,
            projectile=s.projectile_metal_ball,
        ),
        "drone": dict(
            melee_damage_reduction=1.0,
            range_damage_reduction=0.2,
            melee_attack_probability=0.0,
            melee_damage=0,
            range_damage=1,
            animation_idle=a.enemy_drone_idle,
            animation_attack_melee=a.enemy_drone_idle,
            animation_attack_ranged=a.enemy_drone_ranged_attack,
            projectile=s.projectile_small_bullet,
        ),
        "servitor": dict(
            melee_damage_reduction=0.7,
            range_damage_reduction=0.3,
            melee_attack_probability=0.5,
            melee_damage=1,
            range_damage=1,
            animation_idle=a.enemy_fanatic_idle,
            animation_attack_melee=a.enemy_fanatic_melee_attack,
            animation_attack_ranged=a.enemy_fanatic_ranged_attack,
            projectile=s.projectile_spikes,
        ),
        "last_guardian": dict(
            melee_damage_reduction=0.5,
            range_damage_reduction=0.5,
            melee_attack_probability=0.5,
            melee_damage=1,
            range_damage=1,
            animation_idle=a.enemy_lastguardian_idle,
            animation_attack_melee=a.enemy_lastguardian_melee_attack,
            animation_attack_ranged=a.enemy_lastguardian_ranged_attack,
            projectile=s.projectile_sun_core,
        ),
    }
    if name not in configs:
        raise ValueError(f"Unknown enemy: {name}")
    return _FightEnemy(
        hp=hp,
        max_hp=hp,
        name=name,
        pos_interpolator=0.0,
        ready_time=0.0,
        warned=False,
        **configs[name],  # type: ignore
    )


def _make_fight_player(assets: Assets, stats: PlayerStats) -> _FightPlayer:
    a = assets.animations
    return _FightPlayer(
        stats=stats,
        projectile=assets.sprites.projectile_brass_bullet,
        pos_interpolator=0.0,
        parry_state=_ParryState.NOT_YET_TRIED,
        animation_idle=a.player_fight_idle,
        animation_attack_melee=a.player_fight_melee_attack,
        animation_attack_range=a.player_fight_ranged_attack,
    )


class FightScene(Scene):
    __player: _FightPlayer
    __enemy: _FightEnemy
    __state: _FightState
    __projectile_interpolator: float
    __win_jingle_time: float

    def __init__(self, assets: Assets, stats: PlayerStats, enemy: ObjectEnemy) -> None:
        super().__init__(assets)
        self.__player = _make_fight_player(assets, stats)
        self.__enemy = _make_enemy(assets, enemy.hp, enemy.enemy_name)
        self.__state = _FightState.PLAYER_TURN
        self.__projectile_interpolator = 0.0
        self.__win_jingle_time = 0.0

        for event_type in [
            FightPlayerAttackMeleeEvent,
            FightPlayerAttackRangeEvent,
            FightPlayerParryEvent,
            FightPlayerDeflectEvent,
            FightPlayerTurnEvent,
            FightPlayerTakeHitEvent,
            FightEnemyTurnEvent,
            FightEnemyAttackMeleeEvent,
            FightEnemyAttackRangedEvent,
            FightEnemyTakeHitEvent,
            FightEnemyDeadEvent,
        ]:
            self.subscribe(event_type, self.handle_event)

    @override
    def update(self) -> None:
        self.__update_player()
        self.__update_enemy()

        if self.__state != _FightState.WIN_JINGLE and self.__enemy.hp <= 0:
            self.dispatch(FightEnemyDeadEvent())
        if self.__player.hp <= 0:
            self.dispatch(LoseEvent())

        match self.__state:
            case _FightState.PLAYER_TURN:
                pass

            case _FightState.PLAYER_ATTACKING_MELEE:
                self.__player.pos_interpolator += rl.get_frame_time()
                if self.__player.pos_interpolator > 1:
                    self.__player.pos_interpolator = 0
                    self.__enemy.pending = _PendingMelee(self.__player.melee_damage)
                    self.dispatch(FightEnemyTakeHitEvent())

            case _FightState.PLAYER_ATTACKING_RANGE:
                self.__projectile_interpolator += rl.get_frame_time() * PROJECTILE_SPEED
                if self.__projectile_interpolator > 1:
                    self.__projectile_interpolator = 0
                    self.__enemy.pending = _PendingRanged(self.__player.range_damage)
                    self.dispatch(FightEnemyTakeHitEvent())

            case _FightState.PLAYER_TAKING_HIT:
                match self.__player.parry_state:
                    case _ParryState.NOT_YET_TRIED | _ParryState.UNSUCCESSFUL:
                        self.dispatch(FightPlayerGetHurtEvent())
                        if self.__player.shield > 0:
                            self.__player.shield -= 1
                        else:
                            self.__player.hp -= 1
                    case _ParryState.SUCCESSFUL_PARRY:
                        self.dispatch(FightParrySuccessEvent())
                    case _ParryState.SUCCESSFUL_DEFLECT:
                        self.dispatch(FightDeflectSuccessEvent())
                self.dispatch(FightPlayerTurnEvent())

            case _FightState.ENEMY_TURN:
                self.__enemy.ready_time -= rl.get_frame_time()
                if (
                    self.__enemy.ready_time < ENEMY_WARN_TIME
                    and not self.__enemy.warned
                ):
                    self.dispatch(FightEnemyWarnPleaseEvent())
                    self.__enemy.warned = True
                if self.__enemy.ready_time < 0:
                    if random.random() < self.__enemy.melee_attack_probability:
                        self.dispatch(FightEnemyAttackMeleeEvent())
                    else:
                        self.dispatch(FightEnemyAttackRangedEvent())

            case _FightState.ENEMY_ATTACKING_MELEE:
                self.__enemy.pos_interpolator += (
                    rl.get_frame_time() * ENEMY_ATTACK_VELOCITY
                )
                if self.__enemy.pos_interpolator > 1:
                    self.__enemy.pos_interpolator = 0
                    self.dispatch(FightPlayerTakeHitEvent())

            case _FightState.ENEMY_ATTACKING_RANGE:
                self.__projectile_interpolator += (
                    rl.get_frame_time() * ENEMY_ATTACK_VELOCITY * PROJECTILE_SPEED
                )
                if self.__projectile_interpolator > 1:
                    self.__projectile_interpolator = 0
                    self.dispatch(FightPlayerTakeHitEvent())

            case _FightState.ENEMY_TAKING_HIT:
                match self.__enemy.pending:
                    case _PendingMelee() as pen:
                        self.__enemy.hp -= int(
                            pen.damage * (1 - self.__enemy.melee_damage_reduction)
                        )
                        self.dispatch(FightEnemyTurnEvent())
                    case _PendingRanged() as pen:
                        self.__enemy.hp -= int(
                            pen.damage * (1 - self.__enemy.range_damage_reduction)
                        )
                        self.dispatch(FightEnemyTurnEvent())

            case _FightState.WIN_JINGLE:
                self.__win_jingle_time += rl.get_frame_time()
                if self.__win_jingle_time > WIN_JINGLE_TIME:
                    self.dispatch(FightWinEvent())

    @override
    def draw(self) -> None:
        self.__draw_background(self.assets.sprites.fight_background)
        self.__draw_player()
        self.__draw_enemy()
        self.__draw_ui()

    def handle_event(self, event: Event) -> None:
        match event:
            case FightPlayerAttackMeleeEvent():
                self.__player.animation_current = self.__player.animation_attack_melee
                self.__player.animation_attack_melee.reset()
                self.__state = _FightState.PLAYER_ATTACKING_MELEE

            case FightPlayerAttackRangeEvent():
                self.__player.animation_current = self.__player.animation_attack_range
                self.__player.animation_attack_range.reset()
                self.__state = _FightState.PLAYER_ATTACKING_RANGE

            case FightEnemyTurnEvent():
                self.__player.parry_state = _ParryState.NOT_YET_TRIED
                self.__state = _FightState.ENEMY_TURN
                self.__enemy.ready_time = ENEMY_READY_TIME
                self.__enemy.warned = False

            case FightEnemyAttackMeleeEvent():
                self.__state = _FightState.ENEMY_ATTACKING_MELEE
                self.__enemy.pos_interpolator = 0
                self.__enemy.animation_current = self.__enemy.animation_attack_melee
                self.__enemy.animation_attack_melee.reset()

            case FightEnemyAttackRangedEvent():
                self.__state = _FightState.ENEMY_ATTACKING_RANGE
                self.__enemy.pos_interpolator = 0
                self.__enemy.animation_current = self.__enemy.animation_attack_ranged
                self.__enemy.animation_attack_ranged.reset()

            case FightPlayerTurnEvent():
                self.__state = _FightState.PLAYER_TURN

            case FightPlayerTakeHitEvent():
                self.__state = _FightState.PLAYER_TAKING_HIT
                self.__enemy.animation_current = self.__enemy.animation_idle
                self.__enemy.animation_idle.reset()

            case FightPlayerParryEvent():
                left, right = self.__parry_bounds()
                center = self.__parry_center()
                if (
                    self.__state == _FightState.ENEMY_ATTACKING_MELEE
                    and left <= center <= right
                ):
                    self.__player.parry_state = _ParryState.SUCCESSFUL_PARRY
                else:
                    self.__player.parry_state = _ParryState.UNSUCCESSFUL

            case FightPlayerDeflectEvent():
                left, right = self.__parry_bounds()
                center = self.__parry_center()
                if (
                    self.__state == _FightState.ENEMY_ATTACKING_RANGE
                    and left <= center <= right
                ):
                    self.__player.parry_state = _ParryState.SUCCESSFUL_PARRY
                else:
                    self.__player.parry_state = _ParryState.UNSUCCESSFUL

            case FightEnemyTakeHitEvent():
                self.__state = _FightState.ENEMY_TAKING_HIT

            case FightEnemyDeadEvent():
                self.__state = _FightState.WIN_JINGLE

    def __update_player(self) -> None:
        p = self.__player
        if p.animation_current is None:
            p.animation_current = p.animation_idle
        if (
            p.animation_current is not p.animation_idle
            and p.animation_current.index >= len(p.animation_current.frames) - 1
        ):
            p.animation_current = p.animation_idle
        p.animation_current.update()

    def __update_enemy(self) -> None:
        e = self.__enemy
        if e.animation_current is None:
            e.animation_current = e.animation_idle
        if (
            e.animation_current is not e.animation_idle
            and e.animation_current.index >= len(e.animation_current.frames) - 1
        ):
            e.animation_current = e.animation_idle
        e.animation_current.update()

    def __draw_player(self) -> None:
        p = self.__player
        if p.animation_current is None:
            return
        x_start = float(GUYS_PADDING)
        x_end = rl.get_screen_width() - GUYS_PADDING - GUYS_LIMIT
        p.animation_current.draw(
            rl.Vector2(
                ease_in_back(x_start, x_end, p.pos_interpolator),
                rl.get_screen_height() - FIGHT_LINE,
            ),
            centered=True,
            scale=SPRITE_SCALE,
        )

    def __draw_enemy(self) -> None:
        e = self.__enemy
        if e.animation_current is None:
            return
        x_end = float(GUYS_PADDING + GUYS_LIMIT)
        x_start = float(rl.get_screen_width() - GUYS_PADDING)
        e.animation_current.draw(
            rl.Vector2(
                ease_in_back(x_start, x_end, e.pos_interpolator),
                rl.get_screen_height() - FIGHT_LINE,
            ),
            centered=True,
            scale=SPRITE_SCALE,
        )

    def __draw_ui(self) -> None:
        self.__draw_enemy_hp()
        self.__draw_player_stats()

        match self.__state:
            case _FightState.PLAYER_TURN:
                self.__ui_player_turn()
            case _FightState.PLAYER_ATTACKING_RANGE:
                if self.__projectile_interpolator > 0:
                    x_start, x_end = self.__projectile_bounds()
                    center = rl.Vector2(
                        x_start + (x_end - x_start) * self.__projectile_interpolator,
                        rl.get_screen_height() - FIGHT_LINE - 64,
                    )
                    self.__player.projectile.draw(
                        center, scale=SPRITE_SCALE, centered=True
                    )
            case _FightState.ENEMY_TURN:
                if self.__enemy.ready_time < ENEMY_WARN_TIME:
                    self.__ui_player_defending()
            case _FightState.ENEMY_ATTACKING_MELEE:
                self.__ui_player_defending()
            case _FightState.ENEMY_ATTACKING_RANGE:
                x_end, x_start = self.__projectile_bounds()
                center = rl.Vector2(
                    x_start + (x_end - x_start) * self.__projectile_interpolator,
                    rl.get_screen_height() - FIGHT_LINE - 64,
                )
                if self.__enemy.projectile:
                    self.__enemy.projectile.draw(
                        center, scale=SPRITE_SCALE, centered=True
                    )
                self.__ui_player_defending()

    def __ui_player_turn(self) -> None:
        sh = rl.get_screen_height()
        if rl.gui_button(
            rl.Rectangle(
                PADDING, sh - BUTTON_SIZE.y - PADDING, BUTTON_SIZE.x, BUTTON_SIZE.y
            ),
            "Attack Melee",
        ):
            self.dispatch(
                FightPlayerAttackMeleeEvent(damage=self.__player.melee_damage)
            )
        if rl.gui_button(
            rl.Rectangle(
                PADDING,
                sh - BUTTON_SIZE.y * 2 - BUTTON_GAP - PADDING,
                BUTTON_SIZE.x,
                BUTTON_SIZE.y,
            ),
            "Attack Ranged",
        ):
            self.dispatch(
                FightPlayerAttackRangeEvent(damage=self.__player.range_damage)
            )

    def __ui_player_defending(self) -> None:
        self.__draw_parry_bounds()
        self.__draw_parry_marker()
        if self.__player.parry_state == _ParryState.NOT_YET_TRIED:
            sh = rl.get_screen_height()
            if rl.gui_button(
                rl.Rectangle(
                    PADDING, sh - BUTTON_SIZE.y - PADDING, BUTTON_SIZE.x, BUTTON_SIZE.y
                ),
                "Parry",
            ):
                self.dispatch(FightPlayerParryEvent())
            if rl.gui_button(
                rl.Rectangle(
                    PADDING,
                    sh - BUTTON_SIZE.y * 2 - BUTTON_GAP - PADDING,
                    BUTTON_SIZE.x,
                    BUTTON_SIZE.y,
                ),
                "Deflect",
            ):
                self.dispatch(FightPlayerDeflectEvent())

    def __draw_enemy_hp(self) -> None:
        width, height = 300, 20
        ratio = self.__enemy.hp / self.__enemy.max_hp
        sw, sh = rl.get_screen_width(), rl.get_screen_height()
        base_y = sh - height - UI_HEIGHT - PADDING + 100
        base_x = sw - width - PADDING

        rl.draw_rectangle_rec(
            rl.Rectangle(base_x, base_y, width * ratio, height), rl.RED
        )
        rl.draw_rectangle_lines_ex(
            rl.Rectangle(base_x, base_y, width, height), 1, rl.WHITE
        )

        font_size = 32
        text = f"HP: {self.__enemy.hp}/{self.__enemy.max_hp}"
        text_width = rl.measure_text(text, font_size)
        rl.draw_text(
            text,
            sw - (width + text_width) // 2 - PADDING,
            base_y - font_size,
            font_size,
            rl.WHITE,
        )

    def __draw_player_stats(self) -> None:
        font_size = 32
        p = self.__player
        text = f"HP:{p.hp}      Melee dmg.:{p.melee_damage}\nShield:{p.shield} Range dmg.:{p.range_damage}"
        rl.draw_text(
            text,
            PADDING,
            rl.get_screen_height() - UI_HEIGHT - font_size * 2 - PADDING + 100,
            font_size,
            rl.WHITE,
        )

    def __draw_background(self, texture: rl.Texture) -> None:
        rl.clear_background(rl.BLACK)
        aspect = texture.width / texture.height
        width = rl.get_screen_width() + 100.0
        height = width / aspect
        rl.draw_texture_pro(
            texture,
            rl.Rectangle(0, 0, float(texture.width), float(texture.height)),
            rl.Rectangle(
                -50, rl.get_screen_height() - FIGHT_LINE - height * 0.7, width, height
            ),
            rl.Vector2(0, 0),
            0,
            rl.WHITE,
        )

    def __parry_bounds(self) -> tuple[float, float]:
        length = rl.get_screen_width() - GUYS_LIMIT * 2
        left = GUYS_LIMIT + PARRY_OFFSET
        right = GUYS_LIMIT + length * PARRY_WINDOW_SIZE + PARRY_OFFSET
        return left, right

    def __parry_center(self) -> float:
        match self.__state:
            case _FightState.ENEMY_ATTACKING_MELEE:
                x_end = float(GUYS_PADDING + GUYS_LIMIT)
                x_start = float(rl.get_screen_width() - GUYS_PADDING)
                return ease_in_back(x_start, x_end, self.__enemy.pos_interpolator)
            case _FightState.ENEMY_ATTACKING_RANGE:
                left, right = self.__projectile_bounds()
                return right + (left - right) * self.__projectile_interpolator
            case _:
                return -100.0

    def __projectile_bounds(self) -> tuple[float, float]:
        left = GUYS_PADDING + PROJECTILE_LIMIT
        right = rl.get_screen_width() - GUYS_PADDING - PROJECTILE_LIMIT
        return left, right

    def __draw_parry_bounds(self) -> None:
        left, right = self.__parry_bounds()
        up = rl.get_screen_height() - FIGHT_LINE + PARRY_BOUND_HEIGHT * 0.5
        down = rl.get_screen_height() - FIGHT_LINE - PARRY_BOUND_HEIGHT * 0.5
        rl.draw_line_ex(
            rl.Vector2(left, up), rl.Vector2(left, down), PARRY_LINE_THICKNESS, rl.RED
        )
        rl.draw_line_ex(
            rl.Vector2(right, up), rl.Vector2(right, down), PARRY_LINE_THICKNESS, rl.RED
        )

    def __draw_parry_marker(self) -> None:
        x = self.__parry_center()
        y = rl.get_screen_height() - FIGHT_LINE
        rl.draw_circle(int(x), y, 5, rl.BLUE)
