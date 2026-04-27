package game

import rl "vendor:raylib"

@(private = "file")
TEXT_SIZE :: 32

Dead_Screen :: struct {
	texture: rl.Texture2D,
}

dead_screen_make :: proc(assets: ^Assets) -> Dead_Screen {
	return {texture = assets.sprites.bg_dead}
}

dead_screen_ui :: proc(s: ^Dead_Screen, queue: ^Event_Queue) {
	old_size := rl.GuiGetStyle(.DEFAULT, i32(rl.GuiDefaultProperty.TEXT_SIZE))
	rl.GuiSetStyle(.DEFAULT, i32(rl.GuiDefaultProperty.TEXT_SIZE), TEXT_SIZE)
	defer rl.GuiSetStyle(.DEFAULT, i32(rl.GuiDefaultProperty.TEXT_SIZE), old_size)

	rl.ClearBackground(rl.GetColor(0x231d29ff))
	background_texture_centered(s.texture, align_top = true)
	text_centered("Game over!", 64, {0, 0})

	if button_centered("Retry", {200, 50}, {0, 60}) {
		event_dispatch(queue, Event_Menu{})
	}
}
