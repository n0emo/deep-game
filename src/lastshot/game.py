from pathlib import Path
from typing import override
from engine import Application, Context, Texture, Color, Vector2, Rectangle


class Game(Application):
    def __init__(self) -> None:
        self.texture = Texture.load(
            Path("assets", "sprites", "background-main-menu.png")
        )

    @override
    def frame(self, ctx: Context) -> None:
        self.renderer.clear(Color(255, 255, 255, 255))
        self.renderer.texture_pro(
            texture=self.texture,
            source=Rectangle(0, 0, -128, 128),
            dest=Rectangle(0, 0, 128 * 5, 128 * 5),
            origin=Vector2(0, 0),
            rotation=0,
            tint=Color(255, 255, 255, 255),
        )
