package game

import "core:c"
import rl "vendor:raylib"

text_centered :: proc(
	text: cstring,
	font_size: c.int,
	offset: rl.Vector2 = {0, 0},
	color: rl.Color = rl.WHITE,
) {
	text_width := rl.MeasureText(text, font_size)
	x := c.int(f32(rl.GetScreenWidth() - text_width) * 0.5 + offset.x)
	y := c.int(f32(rl.GetScreenHeight() - font_size) * 0.5 + offset.y)
	rl.DrawText(text, x, y, font_size, color)
}

button_centered :: proc(text: cstring, size: rl.Vector2, offset: rl.Vector2) -> bool {
	return rl.GuiButton(
		rl.Rectangle {
			x = (cast(f32)rl.GetScreenWidth() - size.x) * 0.5 + offset.x,
			y = (cast(f32)rl.GetScreenHeight() - size.y) * 0.5 + offset.y,
			width = size.x,
			height = size.y,
		},
		text,
	)
}

slider_centered :: proc(text: cstring, value: ^f32, size: rl.Vector2, offset: rl.Vector2) -> bool {
	value := rl.GuiSliderBar(
		rl.Rectangle {
			x = (cast(f32)rl.GetScreenWidth() - size.x) * 0.5 + offset.x,
			y = (cast(f32)rl.GetScreenHeight() - size.y) * 0.5 + offset.y,
			width = size.x,
			height = size.y,
		},
		text,
		rl.TextFormat("%.0f%%", value^),
		value,
		0,
		100,
	)

	return value == 1
}
