from __future__ import annotations
from lastshot.events import InputGoEvent
from lastshot.direction import Direction
from lastshot.scenes import Scene
import pyray as rl

_KEY_DIRECTION: list[tuple[list[int], Direction]] = [
    ([rl.KeyboardKey.KEY_UP, rl.KeyboardKey.KEY_W], Direction.UP),
    ([rl.KeyboardKey.KEY_DOWN, rl.KeyboardKey.KEY_S], Direction.DOWN),
    ([rl.KeyboardKey.KEY_LEFT, rl.KeyboardKey.KEY_A], Direction.LEFT),
    ([rl.KeyboardKey.KEY_RIGHT, rl.KeyboardKey.KEY_D], Direction.RIGHT),
]


class InputSystem:
    def update(self, scene: Scene) -> None:
        for keys, direction in _KEY_DIRECTION:
            if any(rl.is_key_down(key) for key in keys):
                scene.dispatch(InputGoEvent(direction=direction))
