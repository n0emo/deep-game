from __future__ import annotations
from dataclasses import dataclass
import pyray as rl
from atlas import Atlas


@dataclass
class AnimationFrame:
    rect: rl.Rectangle
    duration: float


@dataclass
class Animation:
    texture: rl.Texture
    frames: list[AnimationFrame]
    loop: bool = True
    time: float = 0
    index: int = 0

    def update(self) -> None:
        if len(self.frames) <= 1:
            return
        self.time += rl.get_frame_time() * 1000
        if self.time > self.frames[self.index].duration:
            self.time -= self.frames[self.index].duration
            self.index += 1
            if self.index >= len(self.frames):
                if self.loop:
                    self.index = 0
                else:
                    self.index = len(self.frames) - 1

    def reset(self) -> None:
        self.time = 0
        self.index = 0

    def draw(self, pos: rl.Vector2, scale: float = 1, centered: bool = False) -> None:
        if not self.frames:
            return
        current_frame = self.frames[self.index]
        width = current_frame.rect.width
        height = current_frame.rect.height
        dest = rl.Rectangle(0, 0, width * scale, height * scale)
        if centered:
            dest.x = pos.x - width * 0.5 * scale
            dest.y = pos.y - height * 0.5 * scale
        else:
            dest.x = pos.x
            dest.y = pos.y
        rl.draw_texture_pro(
            self.texture, current_frame.rect, dest, rl.Vector2(0, 0), 0, rl.WHITE
        )


def animation_frame_from_atlas(atlas: Atlas, frame_name: str) -> AnimationFrame:
    frame = atlas.frames.get(frame_name)
    if frame is None:
        raise KeyError(f"Frame not found: '{frame_name}'")
    return AnimationFrame(rect=frame.frame, duration=frame.duration)
