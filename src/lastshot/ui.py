from __future__ import annotations
import pyray as rl


def text_centered(
    text: str,
    font_size: int,
    offset: rl.Vector2 | None = None,
    color: rl.Color | None = None,
) -> None:
    if offset is None:
        offset = rl.Vector2(0, 0)
    if color is None:
        color = rl.WHITE
    text_width = rl.measure_text(text, font_size)
    x = int((rl.get_screen_width() - text_width) * 0.5 + offset.x)
    y = int((rl.get_screen_height() - font_size) * 0.5 + offset.y)
    rl.draw_text(text, x, y, font_size, color)


def button_centered(
    text: str,
    size: rl.Vector2,
    offset: rl.Vector2 | None = None,
) -> bool:
    if offset is None:
        offset = rl.Vector2(0, 0)
    result = rl.gui_button(
        rl.Rectangle(
            (rl.get_screen_width() - size.x) * 0.5 + offset.x,
            (rl.get_screen_height() - size.y) * 0.5 + offset.y,
            size.x,
            size.y,
        ),
        text,
    )
    return result == 1


def slider_centered(
    text: str,
    value: float,
    size: rl.Vector2,
    offset: rl.Vector2 | None = None,
) -> tuple[bool, float]:
    if offset is None:
        offset = rl.Vector2(0, 0)

    c_value = rl.ffi.new("float *", value)
    rl.gui_slider_bar(
        rl.Rectangle(
            (rl.get_screen_width() - size.x) * 0.5 + offset.x,
            (rl.get_screen_height() - size.y) * 0.5 + offset.y,
            size.x,
            size.y,
        ),
        text,
        f"{value:.0f}%",
        c_value,
        0,
        100,
    )
    new_value = c_value[0]
    return new_value == 100.0, new_value


def background_texture_centered(texture: rl.Texture, align_top: bool = False) -> None:
    # TODO: this aspect handling may be incorrect but i have square picture and could not test
    aspect = texture.width / texture.height
    x = 0.0
    y = 0.0
    width = float(rl.get_screen_width())
    height = float(rl.get_screen_height())
    if width > height:
        width = height * aspect
        x = (rl.get_screen_width() - width) * 0.5
    else:
        height = width * aspect
        y = (rl.get_screen_height() - height) * 0.5
    if align_top:
        y = 0
    rl.draw_texture_pro(
        texture,
        rl.Rectangle(0, 0, float(texture.width), float(texture.height)),
        rl.Rectangle(x, y, width, height),
        rl.Vector2(0, 0),
        0,
        rl.WHITE,
    )
