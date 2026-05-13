from typing import Callable, List, DefaultDict, Any
from dataclasses import dataclass
from collections import defaultdict


@dataclass
class Event:
    source: Any = None


Callback = Callable[[Event], None]


class EventDispatcher:
    __callbacks: DefaultDict[str, List[Callback]]

    def __init__(self) -> None:
        self.__callbacks = defaultdict(list)

    def subscribe(self, target: str, callback: Callback) -> None:
        self.__callbacks[target].append(callback)

    def unsubscribe(self, target: str, callback: Callback) -> None:
        self.__callbacks[target] = list(
            filter(lambda c: c == callback, self.__callbacks[target])
        )

    def dispatch(self, target: str, event: Event) -> None:
        for callback in self.__callbacks[target]:
            callback(event)
