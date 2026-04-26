package game

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
	bg_texture:     rl.Texture2D,
	using settings: Main_Menu_Settings,
	screen:         Main_Menu_Screen,
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
			master_volume = DEFAULT_MASTER_VOLUME * 100,
			music_volume = DEFAULT_MUSIC_VOLUME * 100,
			sfx_volume = DEFAULT_SFX_VOLUME * 100,
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
		event_dispatch(queue, Event_Button_Pressed{})
	}

	if button_centered("Settings", BUTTON_SIZE, {0, 0}) {
		event_dispatch(queue, Event_Menu_Settings{})
		event_dispatch(queue, Event_Button_Pressed{})
	}

	if button_centered("Exit", BUTTON_SIZE, {0, 60}) {
		event_dispatch(queue, Event_Exit{})
		event_dispatch(queue, Event_Button_Pressed{})
	}
}

@(private = "file")
menu_settings_buttons :: proc(m: ^Main_Menu, queue: ^Event_Queue) {
	slider_centered("Master", &m.master_volume, SLIDER_SIZE, {0, -90})
	slider_centered("Music", &m.settings.music_volume, SLIDER_SIZE, {0, -30})
	slider_centered("SFX", &m.settings.sfx_volume, SLIDER_SIZE, {0, 30})
	if button_centered("Back", BUTTON_SIZE, {0, 90}) {
		event_dispatch(queue, Event_Menu_Home{})
		event_dispatch(queue, Event_Button_Pressed{})
	}

	event_dispatch(
		queue,
		Event_Change_Audio_Volume {
			master_volume = m.master_volume / 100,
			music_volume = m.music_volume / 100,
			sfx_volume = m.sfx_volume / 100,
		},
	)
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
