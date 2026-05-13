from __future__ import annotations
import pyray as rl


def ease_in_expo(a: float, b: float, t: float) -> float:
    if t != 0:
        t = 2 ** (10 * t - 10)
    return _lerp_scalar(a, b, t)


def ease_in_expo_vec(a: rl.Vector2, b: rl.Vector2, t: float) -> rl.Vector2:
    if t != 0:
        t = 2 ** (10 * t - 10)
    return _lerp_vec(a, b, t)


def ease_in_back(a: float, b: float, t: float) -> float:
    t = t * t
    return _lerp_scalar(a, b, t)


def ease_in_back_vec(a: rl.Vector2, b: rl.Vector2, t: float) -> rl.Vector2:
    t = t * t
    return _lerp_vec(a, b, t)


def _lerp_scalar(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def _lerp_vec(a: rl.Vector2, b: rl.Vector2, t: float) -> rl.Vector2:
    return rl.Vector2(
        a.x + (b.x - a.x) * t,
        a.y + (b.y - a.y) * t,
    )
