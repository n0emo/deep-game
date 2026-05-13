from __future__ import annotations
from enum import Enum, auto
import pyray as rl


class Direction(Enum):
    UP = auto()
    DOWN = auto()
    LEFT = auto()
    RIGHT = auto()

    def to_vec(self) -> rl.Vector2:
        match self:
            case Direction.UP:
                return rl.Vector2(0, -1)
            case Direction.DOWN:
                return rl.Vector2(0, 1)
            case Direction.LEFT:
                return rl.Vector2(-1, 0)
            case Direction.RIGHT:
                return rl.Vector2(1, 0)

    def to_vec_i32(self) -> tuple[int, int]:
        match self:
            case Direction.UP:
                return (0, -1)
            case Direction.DOWN:
                return (0, 1)
            case Direction.LEFT:
                return (-1, 0)
            case Direction.RIGHT:
                return (1, 0)
