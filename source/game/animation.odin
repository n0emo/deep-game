package game

import atlas "../atlas"
import "core:slice"
import rl "vendor:raylib"

Animation :: struct {
	texture: rl.Texture2D,
	time:    f32,
	index:   int,
	frames:  []Animation_Frame,
}

animation_make :: proc(texture: rl.Texture2D, frames: []Animation_Frame) -> Animation {
	frames_clone := slice.clone(frames)
	return Animation{texture = texture, frames = frames_clone, time = 0, index = 0}
}

animation_destroy :: proc(animation: ^Animation) {
	delete(animation.frames)
}

animation_update :: proc(animation: ^Animation) {
	animation.time += rl.GetFrameTime() * 1000
	if animation.time > animation.frames[animation.index].duration {
		animation.time -= animation.frames[animation.index].duration
		animation.index += 1
		if animation.index >= len(animation.frames) {
			animation.index = 0
		}
	}
}

animation_draw :: proc(animation: ^Animation, pos: rl.Vector2) {
	current_frame := animation.frames[animation.index]
	dest := rl.Rectangle {
		x      = pos.x,
		y      = pos.y,
		width  = current_frame.rect.width,
		height = current_frame.rect.height,
	}
	rl.DrawTexturePro(animation.texture, current_frame.rect, dest, 0, 0, rl.WHITE)
}

Animation_Frame :: struct {
	rect:     rl.Rectangle,
	duration: f32,
}

animation_frame_from_atlas :: proc(atlas: ^atlas.Atlas, frame: string) -> Animation_Frame {
	frame := atlas.frames[frame]
	return {rect = frame.frame, duration = frame.duration}
}
