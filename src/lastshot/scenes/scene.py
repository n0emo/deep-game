from abc import ABC, abstractmethod

from lastshot.assets import Assets
from lastshot.events import Event, EventDispatcher, Callback
from typing import Type, TypeVar

E = TypeVar("E", bound=Event)


class Scene(ABC):
    __assets: Assets
    __dispatcher: EventDispatcher

    def __init__(self, assets: Assets) -> None:
        self.__assets = assets
        self.__dispatcher = EventDispatcher()

    @property
    def assets(self) -> Assets:
        return self.__assets

    def dispatch(self, event: Event) -> None:
        self.__dispatcher.dispatch(event)

    def subscribe(self, event_type: Type[E], callback: Callback) -> None:
        self.__dispatcher.subscribe(event_type, callback)

    def unsubscribe(self, event_type: Type[E], callback: Callback) -> None:
        self.__dispatcher.unsubscribe(event_type, callback)

    def handle_event(self, event: Event) -> None:
        _ = event
        pass

    @abstractmethod
    def draw(self) -> None: ...

    @abstractmethod
    def update(self) -> None: ...
