package game

import atlas "../atlas"
import "core:fmt"
import rl "vendor:raylib"

Animation :: struct {
	texture: rl.Texture2D,
	time:    f32,
	index:   int,
	frames:  [dynamic; 8]Animation_Frame,
	loop:    bool,
}

animation_make :: proc(
	texture: rl.Texture2D,
	frames: []Animation_Frame,
	loop: bool = true,
) -> Animation {
	animation := Animation {
		texture = texture,
		time    = 0,
		index   = 0,
		loop    = loop,
	}
	for frame in frames {
		append(&animation.frames, frame)
	}
	return animation
}

animation_update :: proc(animation: ^Animation) {
	if len(animation.frames) <= 1 {
		return
	}

	animation.time += rl.GetFrameTime() * 1000
	if animation.time > animation.frames[animation.index].duration {
		animation.time -= animation.frames[animation.index].duration
		animation.index += 1
		if animation.index >= len(animation.frames) {
			if animation.loop {
				animation.index = 0
			} else {
				animation.index = len(animation.frames) - 1
			}
		}
	}
}

animation_reset :: proc(animation: ^Animation) {
	animation.time = 0
	animation.index = 0
}

animation_draw :: proc(
	animation: ^Animation,
	pos: rl.Vector2,
	scale: f32 = 1,
	centered: bool = false,
) {
	if len(animation.frames) == 0 {
		return
	}

	current_frame := animation.frames[animation.index]
	width := current_frame.rect.width
	height := current_frame.rect.height

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

	rl.DrawTexturePro(animation.texture, current_frame.rect, dest, 0, 0, rl.WHITE)
}

Animation_Frame :: struct {
	rect:     rl.Rectangle,
	duration: f32,
}

animation_frame_from_atlas :: proc(atlas: atlas.Atlas, frame_name: string) -> Animation_Frame {
	frame, ok := atlas.frames[frame_name]
	if !ok {
		panic(fmt.tprintf("Frame not found: '%s'", frame_name))
	}
	return {rect = frame.frame, duration = frame.duration}
}
