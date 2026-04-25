package game

import "core:c"
import rl "vendor:raylib"

@(private = "file")
TEXT_SIZE :: 32

@(private = "file")
BUTTON_SIZE :: rl.Vector2{300, 50}

@(private = "file")
SLIDER_SIZE :: rl.Vector2{300, 50}

@(private = "file")
PANEL_SIZE :: rl.Vector2{550, 400}


Main_Menu :: struct {
	bg_texture: rl.Texture2D,
	settings:   Main_Menu_Settings,
	screen:     Main_Menu_Screen,
}

@(private = "file")
Main_Menu_Settings :: struct {
	master_volume: f32,
	music_volume:  f32,
	sfx_volume:    f32,
}

@(private = "file")
Main_Menu_Screen :: enum {
	Home,
	Settings,
}

main_menu_make :: proc(assets: ^Assets) -> Main_Menu {
	return {
		bg_texture = assets.sprites.main_menu,
		settings = Main_Menu_Settings {
			master_volume = 50.0,
			music_volume = 100.0,
			sfx_volume = 100.0,
		},
		screen = .Home,
	}
}

main_menu_ui :: proc(m: ^Main_Menu, queue: ^Event_Queue) {
	menu_bg(m)

	old_size := rl.GuiGetStyle(.DEFAULT, i32(rl.GuiDefaultProperty.TEXT_SIZE))
	rl.GuiSetStyle(.DEFAULT, i32(rl.GuiDefaultProperty.TEXT_SIZE), TEXT_SIZE)
	defer rl.GuiSetStyle(.DEFAULT, i32(rl.GuiDefaultProperty.TEXT_SIZE), old_size)

	text_centered("Deep Game", 64, offset = {0, -300})
	menu_panel(PANEL_SIZE)
	switch m.screen {
	case .Home:
		menu_home_buttons(m, queue)
	case .Settings:
		menu_settings_buttons(m, queue)
	}
}

main_menu_handle_event :: proc(m: ^Main_Menu, event: Event) {
	#partial switch e in event {
	case Event_Menu_Settings:
		m.screen = .Settings
	case Event_Menu_Home:
		m.screen = .Home
	}
}

@(private = "file")
menu_panel :: proc(size: rl.Vector2) {
	rec := rl.Rectangle {
		x      = (cast(f32)rl.GetScreenWidth() - size.x) * 0.5,
		y      = (cast(f32)rl.GetScreenHeight() - size.y) * 0.5,
		width  = size.x,
		height = size.y,
	}

	rl.DrawRectangleRounded(rec, 0.2, 3, rl.Fade(rl.BEIGE, 0.8))
}

@(private = "file")
menu_home_buttons :: proc(m: ^Main_Menu, queue: ^Event_Queue) {
	if button_centered("Start Game", BUTTON_SIZE, {0, -60}) {
		event_dispatch(queue, Event_Start_Game{})
	}

	if button_centered("Settings", BUTTON_SIZE, {0, 0}) {
		event_dispatch(queue, Event_Menu_Settings{})
	}

	if button_centered("Exit", BUTTON_SIZE, {0, 60}) {
		event_dispatch(queue, Event_Exit{})
	}
}

@(private = "file")
menu_settings_buttons :: proc(m: ^Main_Menu, queue: ^Event_Queue) {
	if slider_centered("Master", &m.settings.master_volume, SLIDER_SIZE, {0, -90}) {
		event_dispatch(queue, Event_Change_Master_Volume{volume = m.settings.sfx_volume / 100.0})
	}

	if slider_centered("Music", &m.settings.music_volume, SLIDER_SIZE, {0, -30}) {
		event_dispatch(queue, Event_Change_Music_Volume{volume = m.settings.sfx_volume / 100.0})
	}

	if slider_centered("SFX", &m.settings.sfx_volume, SLIDER_SIZE, {0, 30}) {
		event_dispatch(queue, Event_Change_Sfx_Volume{volume = m.settings.sfx_volume / 100.0})
	}

	if button_centered("Back", BUTTON_SIZE, {0, 90}) {
		event_dispatch(queue, Event_Menu_Home{})
	}
}


@(private = "file")
menu_bg :: proc(m: ^Main_Menu) {
	sw := f32(rl.GetScreenWidth())
	sh := f32(rl.GetScreenHeight())
	tw := f32(m.bg_texture.width)
	th := f32(m.bg_texture.height)

	scale := max(sw / tw, sh / th)

	src := rl.Rectangle{0, 0, tw, th}
	dst := rl.Rectangle{(sw - tw * scale) / 2, (sh - th * scale) / 2, tw * scale, th * scale}

	rl.DrawTexturePro(m.bg_texture, src, dst, {0, 0}, 0, rl.WHITE)
}

@(private = "file")
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

@(private = "file")
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

@(private = "file")
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
