package game

import "../atlas"
import rl "vendor:raylib"

Sprite :: struct {
	frame:   atlas.Frame,
	texture: rl.Texture2D,
}

sprite_get :: proc(a: ^atlas.Atlas, name: string) -> (sprite: Sprite, ok: bool) {
	sprite.frame = a.frames[name] or_return
	sprite.texture = a.texture
	return sprite, true
}

sprite_draw :: proc(
	sprite: Sprite,
	pos: rl.Vector2,
	scale: f32 = 1,
	centered: bool = false,
	mirror_horizontal: bool = false,
) {
	frame := sprite.frame.frame
	width := frame.width
	height := frame.height

	dest := rl.Rectangle {
		width  = width * scale,
		height = height * scale,
	}

	if centered {
		dest.x = pos.x - width * 0.5 * scale
		dest.y = pos.y - height * 0.5 * scale
	} else {
		dest.x = pos.x
		dest.y = pos.y
	}

	if mirror_horizontal {
		frame.width *= -1
		frame.height *= -1
	}

	rl.DrawTexturePro(sprite.texture, frame, dest, 0, 0, rl.WHITE)
}
