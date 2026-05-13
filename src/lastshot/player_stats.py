from __future__ import annotations
from dataclasses import dataclass


@dataclass
class PlayerStats:
    hp: int = 1
    shield: int = 3
    melee_damage: int = 3
    range_damage: int = 3
