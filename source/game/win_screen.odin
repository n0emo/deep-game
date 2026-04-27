package game

import rl "vendor:raylib"

@(private = "file")
TEXT_SIZE :: 32

Win_Screen :: struct {
	texture: rl.Texture2D,
}

win_screen_make :: proc(assets: ^Assets) -> Win_Screen {
	return {texture = assets.sprites.bg_win}
}

win_screen_ui :: proc(s: ^Win_Screen, queue: ^Event_Queue) {
	old_size := rl.GuiGetStyle(.DEFAULT, i32(rl.GuiDefaultProperty.TEXT_SIZE))
	rl.GuiSetStyle(.DEFAULT, i32(rl.GuiDefaultProperty.TEXT_SIZE), TEXT_SIZE)
	defer rl.GuiSetStyle(.DEFAULT, i32(rl.GuiDefaultProperty.TEXT_SIZE), old_size)


	rl.ClearBackground(rl.GetColor(0x231d29ff))
	background_texture_centered(s.texture)

	size :: rl.Vector2{720, 300}
	rec := rl.Rectangle {
		x      = (cast(f32)rl.GetScreenWidth() - size.x) * 0.5,
		y      = (cast(f32)rl.GetScreenHeight() - size.y) * 0.5,
		width  = size.x,
		height = size.y,
	}

	rl.DrawRectangleRounded(rec, 0.2, 3, rl.Fade(rl.BROWN, 0.6))

	text_centered("You saved the world!\nThanks for playing.", 64, {0, -70})

	if button_centered("Back to main menu", {500, 50}, {0, 70}) {
		event_dispatch(queue, Event_Menu{})
	}
}
