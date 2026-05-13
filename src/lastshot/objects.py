from __future__ import annotations
from dataclasses import dataclass
from tiled import Object as TiledObject


@dataclass
class ObjectSpawnpoint:
    pass


@dataclass
class ObjectTransition:
    pass


@dataclass
class ObjectEnemy:
    hp: int
    enemy_name: str


ObjectProperties = ObjectSpawnpoint | ObjectTransition | ObjectEnemy


@dataclass
class Object:
    id: int
    x: float
    y: float
    width: float
    height: float
    properties: ObjectProperties


def object_make(obj: TiledObject) -> Object:
    properties: ObjectProperties | None = None
    match obj.type:
        case "spawnpoint":
            properties = ObjectSpawnpoint()
        case "transition":
            properties = ObjectTransition()
        case "enemy":
            assert isinstance(obj.properties["hp"], int)
            assert isinstance(obj.properties["enemy_name"], str)

            properties = ObjectEnemy(
                hp=obj.properties["hp"],
                enemy_name=obj.properties["enemy_name"],
            )
        case _:
            raise ValueError(f"Unknown object type: {obj.type}")

    return Object(
        id=obj.id,
        x=obj.x,
        y=obj.y,
        width=float(obj.width),
        height=float(obj.height),
        properties=properties,
    )
