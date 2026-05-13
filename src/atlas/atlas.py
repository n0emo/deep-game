import json
import os
import pyray as rl
from dataclasses import dataclass


@dataclass
class Frame:
    frame: rl.Rectangle
    rotated: bool
    trimmed: bool
    sprite_source_size: rl.Rectangle
    source_size: rl.Vector2
    duration: float


@dataclass
class Atlas:
    texture: rl.Texture
    frames: dict[str, Frame]

    @staticmethod
    def load(path: str) -> "Atlas":
        with open(path, "r") as f:
            desc = json.load(f)

        image_path = os.path.join(os.path.dirname(path), desc["meta"]["image"])
        texture = rl.load_texture(image_path)

        frames = {}
        for name, frame in desc["frames"].items():
            r = frame["frame"]
            sss = frame["spriteSourceSize"]
            ss = frame["sourceSize"]
            frames[name] = Frame(
                frame=rl.Rectangle(r["x"], r["y"], r["w"], r["h"]),
                rotated=frame["rotated"],
                trimmed=frame["trimmed"],
                sprite_source_size=rl.Rectangle(sss["x"], sss["y"], sss["w"], sss["h"]),
                source_size=rl.Vector2(ss["w"], ss["h"]),
                duration=frame["duration"],
            )

        return Atlas(texture=texture, frames=frames)

    def unload(self) -> None:
        rl.unload_texture(self.texture)
