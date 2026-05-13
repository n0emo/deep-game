from __future__ import annotations
from dataclasses import dataclass
import pyray as rl
from atlas import Atlas, Frame


@dataclass
class Sprite:
    frame: Frame
    texture: rl.Texture

    def draw(
        self,
        pos: rl.Vector2,
        scale: float = 1,
        centered: bool = False,
        mirror_horizontal: bool = False,
    ) -> None:
        rect = rl.Rectangle(
            self.frame.frame.x,
            self.frame.frame.y,
            self.frame.frame.width,
            self.frame.frame.height,
        )
        width = rect.width
        height = rect.height
        dest = rl.Rectangle(0, 0, width * scale, height * scale)
        if centered:
            dest.x = pos.x - width * 0.5 * scale
            dest.y = pos.y - height * 0.5 * scale
        else:
            dest.x = pos.x
            dest.y = pos.y
        if mirror_horizontal:
            rect.width *= -1
            rect.height *= -1
        rl.draw_texture_pro(self.texture, rect, dest, rl.Vector2(0, 0), 0, rl.WHITE)


def sprite_get(atlas: Atlas, name: str) -> Sprite:
    frame = atlas.frames.get(name)
    if frame is None:
        raise KeyError(f"Sprite not found: '{name}'")
    return Sprite(frame=frame, texture=atlas.texture)
