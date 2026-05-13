from __future__ import annotations
from typing import Callable, Any, Type, TypeVar
from dataclasses import dataclass, field
from collections import defaultdict

from lastshot.objects import Object, ObjectEnemy, ObjectSpawnpoint
from .direction import Direction


@dataclass
class Event:
    source: Any = None


E = TypeVar("E", bound=Event)
Callback = Callable[[Any], None]


class EventDispatcher:
    __callbacks: dict[type, list[Callback]]

    def __init__(self) -> None:
        self.__callbacks = defaultdict(list)

    def subscribe(self, event_type: Type[E], callback: Callback) -> None:
        self.__callbacks[event_type].append(callback)

    def unsubscribe(self, event_type: Type[E], callback: Callback) -> None:
        callbacks = self.__callbacks[event_type]
        try:
            callbacks.remove(callback)
        except ValueError:
            pass

    def dispatch(self, event: Event) -> None:
        for callback in list(self.__callbacks[type(event)]):
            callback(event)


@dataclass
class StartGameEvent(Event):
    pass


@dataclass
class ExitEvent(Event):
    pass


@dataclass
class MenuEvent(Event):
    pass


@dataclass
class MenuHomeEvent(Event):
    pass


@dataclass
class MenuSettingsEvent(Event):
    pass


# --- Audio ---


@dataclass
class ChangeAudioVolumeEvent(Event):
    master_volume: float = 1.0
    music_volume: float = 1.0
    sfx_volume: float = 1.0


@dataclass
class InputGoEvent(Event):
    direction: Direction = Direction.DOWN


@dataclass
class ButtonPressedEvent(Event):
    pass


@dataclass
class PlayerMovingEvent(Event):
    pass


@dataclass
class PlayerStoppedEvent(Event):
    direction: Direction = Direction.DOWN


@dataclass
class TransitionEvent(Event):
    pass


@dataclass
class EndTransitioningEvent(Event):
    pass


@dataclass
class FightEncounterEvent(Event):
    obj: Object = field(
        default_factory=lambda: Object(
            id=0, x=0, y=0, width=0, height=0, properties=ObjectSpawnpoint()
        )
    )
    enemy: ObjectEnemy = field(default_factory=lambda: ObjectEnemy(hp=0, enemy_name=""))


@dataclass
class FightBeginEvent(Event):
    obj: Object = field(
        default_factory=lambda: Object(
            id=0, x=0, y=0, width=0, height=0, properties=ObjectSpawnpoint()
        )
    )
    enemy: ObjectEnemy = field(default_factory=lambda: ObjectEnemy(hp=0, enemy_name=""))


@dataclass
class FightRandomEncounterEvent(Event):
    pass


@dataclass
class FightPlayerTurnEvent(Event):
    pass


@dataclass
class FightEnemyTurnEvent(Event):
    pass


@dataclass
class FightPlayerAttackMeleeEvent(Event):
    damage: int = 0


@dataclass
class FightPlayerAttackRangeEvent(Event):
    damage: int = 0


@dataclass
class FightPlayerParryEvent(Event):
    pass


@dataclass
class FightPlayerDeflectEvent(Event):
    pass


@dataclass
class FightPlayerTakeHitEvent(Event):
    pass


@dataclass
class FightPlayerGetHurtEvent(Event):
    pass


@dataclass
class FightEnemyWarnEvent(Event):
    pass


@dataclass
class FightEnemyWarnPleaseEvent(Event):
    pass


@dataclass
class FightEnemyAttackMeleeEvent(Event):
    pass


@dataclass
class FightEnemyAttackRangedEvent(Event):
    pass


@dataclass
class FightEnemyTakeHitEvent(Event):
    pass


@dataclass
class FightEnemyDeadEvent(Event):
    pass


@dataclass
class FightWinEvent(Event):
    pass


@dataclass
class FightParrySuccessEvent(Event):
    pass


@dataclass
class FightDeflectSuccessEvent(Event):
    pass


@dataclass
class WinEvent(Event):
    pass


@dataclass
class LoseEvent(Event):
    pass
