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

// NOTE: this functions always returns false on web platform for some reason
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

background_texture_centered :: proc(texture: rl.Texture, align_top: bool = false) {
	// TODO: this aspect handling may be incorect but i have square picture and could not test
	aspect := f32(texture.width) / f32(texture.height)
	x := f32(0)
	y := f32(0)
	width := f32(rl.GetScreenWidth())
	height := f32(rl.GetScreenHeight())
	if width > height {
		width = height * aspect
		x = (f32(rl.GetScreenWidth()) - width) * 0.5
	} else {
		height = width * aspect
		y = (f32(rl.GetScreenHeight()) - height) * 0.5
	}

	if align_top {
		y = 0
	}

	rl.DrawTexturePro(
		texture,
		{x = 0, y = 0, width = f32(texture.width), height = f32(texture.height)},
		{x = x, y = y, width = width, height = height},
		0,
		0,
		rl.WHITE,
	)
}
