package game

import rl "vendor:raylib"

Pause :: enum {
	Pause,
	Continue,
	Settings,
	Exit,
}

Settings :: enum {
	Sound,
	Graphics,
}

Screen :: union {
	Pause,
	Settings,
}

GameSettings :: struct {
	volume:     f32,
	music:      f32,
	screensize: int,
	ui_color:   string,
}

Window :: struct {
	width:  f32,
	height: f32,
	x:      f32,
	y:      f32,
}

screen: Screen
settings: GameSettings

draw_background :: proc() {

}

button_size :: proc(size: i32) {
	rl.GuiSetStyle(.DEFAULT, i32(rl.GuiDefaultProperty.TEXT_SIZE), size)
}

draw_btn_relative :: proc(win: Window, y: f32, text: cstring) -> bool {
	return rl.GuiButton(
		rl.Rectangle {
			get_relative_width_center(win) - win.width / 4,
			get_relative_height_center(win) - win.height / 2 + 20 + y,
			win.width / 2,
			win.height / 10,
		},
		text,
	)
}
get_relative_width_center :: proc(w: Window) -> f32 {
	return w.x + w.width / 2
}

get_relative_height_center :: proc(w: Window) -> f32 {
	return w.y + w.height / 2
}

draw_slide_relative :: proc(win: Window, y: f32, sound_type: ^f32, text: cstring) {
	rl.GuiSliderBar(
		rl.Rectangle {
			get_relative_width_center(win) - win.width / 8,
			get_relative_height_center(win) - win.height / 2 + 20 + y,
			get_relative_width_center(win) * 0.35,
			get_relative_height_center(win) * 0.07,
		},
		text,
		rl.TextFormat("%.2f", sound_type^),
		sound_type,
		0,
		100,
	)
}

main_menu_buttons :: proc(win: Window) {
	if draw_btn_relative(
		win,
		get_relative_height_center(win) * 0.05,
		"Continue",
	) {screen = Pause.Continue}
	if draw_btn_relative(
		win,
		get_relative_height_center(win) * 0.20,
		"Settings",
	) {screen = Pause.Settings}
	if draw_btn_relative(win, get_relative_height_center(win) * 0.35, "Exit") {screen = Pause.Exit}
}

settings_menu_buttons :: proc(win: Window) {
	if draw_btn_relative(
		win,
		get_relative_height_center(win) * 0.05,
		"Sounds",
	) {screen = Settings.Sound}
	if draw_btn_relative(
		win,
		get_relative_height_center(win) * 0.20,
		"Graphics",
	) {screen = Settings.Graphics}
	if draw_btn_relative(
		win,
		get_relative_height_center(win) * 0.35,
		"Back",
	) {screen = Pause.Pause}
}

volume_menu_buttons :: proc(win: Window) {
	draw_slide_relative(win, get_relative_height_center(win) * 0.05, &settings.volume, "Volume")
	draw_slide_relative(win, get_relative_height_center(win) * 0.20, &settings.music, "Music")
	if draw_btn_relative(
		win,
		get_relative_height_center(win) * 0.35,
		"Back",
	) {screen = Pause.Pause}
}

draw_float_window :: proc() {
	width: f32 = f32(rl.GetScreenWidth()) / 1.8
	height: f32 = f32(rl.GetScreenHeight()) / 1.8
	x := f32(rl.GetScreenWidth()) / 2.0 - width / 2.0
	y := f32(rl.GetScreenHeight()) / 2.0 - height / 2.0

	win := Window{width, height, x, y}

	rec := rl.Rectangle{x, y, width, height}

	rl.DrawText(
		"Main Menu",
		i32(get_relative_width_center(win)) - 50,
		i32(get_relative_height_center(win)) / 5,
		20,
		rl.BLACK,
	)
	//rl.DrawRectangleRec(rec, rl.RED)
	rl.DrawRectangleRounded(rec, 0.2, 3, rl.Fade(rl.MAROON, 0.7))
	
	#partial switch s in screen {
	case Settings:
		if s == .Sound {
			volume_menu_buttons(win)
		}
		if s == .Graphics {
		}
	case Pause:
		if s == .Pause {

			main_menu_buttons(win)
		}
		if s == .Settings {
			settings_menu_buttons(win)
		}

	}
}

menu :: proc() {
	rl.DrawFPS(10, 10)
	rl.BeginDrawing()
	button_size(32)
	draw_float_window()
}
