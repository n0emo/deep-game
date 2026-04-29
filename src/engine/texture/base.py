from abc import ABC, abstractmethod
from pathlib import Path
from typing import Self


class BaseTexture(ABC):
    @classmethod
    @abstractmethod
    def load(cls, path: Path) -> "Self": ...

    @abstractmethod
    def unload(self) -> None: ...
