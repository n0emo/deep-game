package game

import rl "vendor:raylib"

SCALE :: 5
World_Transitioning :: struct {
	player:   rl.Texture2D,
	x:        f32,
	y:        f32,
	elapsed:  f32,
	duration: f32,
	end_y:    f32,
	finished: bool,
}

world_transitioning_make :: proc(assets: ^Assets) -> World_Transitioning {
	player := assets.sprites.player_transitioning
	center_x := (f32(rl.GetScreenWidth()) - f32(player.width) * f32(SCALE)) / 2
	end_y := f32(rl.GetScreenHeight()) - f32(player.height) * f32(SCALE)

	return World_Transitioning {
		player = player,
		x = center_x,
		y = 0,
		elapsed = 0,
		duration = 2.0,
		end_y = end_y,
		finished = false,
	}
}

world_transitioning_destroy :: proc(w: ^World_Transitioning) {
}

world_transitioning_update :: proc(w: ^World_Transitioning, queue: ^Event_Queue) {
	if w.finished {
		return
	}

	w.elapsed += rl.GetFrameTime()
	progress := w.elapsed / w.duration
	if progress > 1.0 {
		progress = 1.0
	}

	w.y = ease_in_expo(cast(f32)0.0, w.end_y, progress)

	if progress >= 1.0 {
		w.finished = true
		event_dispatch(queue, Event_End_Transitioning{})
	}
}

world_transitioning_draw :: proc(w: ^World_Transitioning) {
	rl.ClearBackground(rl.BLACK)
	rl.DrawTextureEx(w.player, rl.Vector2{w.x, w.y}, 0.0, f32(SCALE), rl.WHITE)
}

world_transitioning_ui :: proc(w: ^World_Transitioning, queue: ^Event_Queue) {
}

world_transitioning_handle_event :: proc(w: ^World_Transitioning, event: Event) {
}
