package game

import rl "vendor:raylib"

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

Element :: struct {
	data: rawptr,
	call: proc(win: ^Window, y_shift: f32, data: rawptr, g: ^Game_Memory),
}

//settings: GameSettings
settings := GameSettings{50, 50, 100, "RED"}

draw_background :: proc(g: ^Game_Memory) {
	rl.ClearBackground(rl.BLACK)
	texture := g.assets.sprites.main_menu

	sw := f32(rl.GetScreenWidth())
	sh := f32(rl.GetScreenHeight())
	tw := f32(texture.width)
	th := f32(texture.height)

	scale := max(sw / tw, sh / th)

	src := rl.Rectangle{0, 0, tw, th}
	dst := rl.Rectangle{(sw - tw * scale) / 2, (sh - th * scale) / 2, tw * scale, th * scale}

	rl.DrawTexturePro(texture, src, dst, {0, 0}, 0, rl.WHITE)
}

button_size :: proc(size: i32) {
	rl.GuiSetStyle(.DEFAULT, i32(rl.GuiDefaultProperty.TEXT_SIZE), size)
}

get_relative_width_center :: proc(w: ^Window) -> f32 {
	return w.x + w.width / 2
}

get_relative_height_center :: proc(w: ^Window) -> f32 {
	return w.y + w.height / 2
}

draw_btn_relative :: proc(win: ^Window, y: f32, text: cstring) -> bool {
	return rl.GuiButton(
		rl.Rectangle {
			get_relative_width_center(win) - win.width / 4,
			get_relative_height_center(win) - win.height / 1.5 + win.height * y * 0.003,
			win.width / 2,
			win.height / 10,
		},
		text,
	)
}

draw_slide_relative :: proc(win: ^Window, y: f32, sound_type: ^f32, text: cstring) {
	rl.GuiSliderBar(
		rl.Rectangle {
			get_relative_width_center(win) - win.width / 8,
			get_relative_height_center(win) - win.height / 1.5 + win.height * y * 0.003,
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

btn_click :: proc(win: ^Window, name: cstring, y_shift: f32, menu: Game_State, g: ^Game_Memory) {
	if draw_btn_relative(win, y_shift, name) {g.state = menu}
}

ButtonData :: struct {
	name: cstring,
	menu: Game_State,
}

button :: proc(name: cstring, menu: Game_State) -> Element {
	data := new(ButtonData)
	data.name = name
	data.menu = menu


	return Element {
		data = data,
		call = proc(win: ^Window, y_shift: f32, data: rawptr, g: ^Game_Memory) {
			d := (^ButtonData)(data)
			btn_click(win, d.name, y_shift, d.menu, g)
		},
	}
}

SliderData :: struct {
	name:       cstring,
	sound_type: ^f32,
}

slider :: proc(name: cstring, sound_type: ^f32) -> Element {
	data := new(SliderData)
	data.name = name
	data.sound_type = sound_type

	return Element {
		data = data,
		call = proc(win: ^Window, y_shift: f32, data: rawptr, g: ^Game_Memory) {
			data := (^SliderData)(data)
			draw_slide_relative(win, y_shift, data.sound_type, data.name)
		},
	}
}

settings_buttons_list: [dynamic]Element
main_menu_buttons_list: [dynamic]Element
volume_buttons_list: [dynamic]Element

main_menu_init :: proc() {
	append(&main_menu_buttons_list, button("Continue", .GAME))
	append(&main_menu_buttons_list, button("New Game", .NEW_GAME))
	append(&main_menu_buttons_list, button("Settings", .MENU_SETTINGS))
	append(&main_menu_buttons_list, button("Exit", .EXIT))

	append(&settings_buttons_list, button("Sound", .MENU_SOUND))
	append(&settings_buttons_list, button("Graphics", .MENU_GRAPHICS))

	append(&volume_buttons_list, slider("Volume", &settings.volume))
	append(&volume_buttons_list, slider("Music", &settings.music))
	append(&volume_buttons_list, button("Back", .MENU))
}

list_free :: proc(list: ^[dynamic]Element) {
	for elem in list {
		free(elem.data)
	}
	delete(list^)
	list^ = {}
}

main_menu_destroy :: proc() {
	list_free(&main_menu_buttons_list)
	list_free(&settings_buttons_list)
	list_free(&volume_buttons_list)
}

draw_main_menu_buttons :: proc(win: ^Window, g: ^Game_Memory) {
	for i in 0 ..< len(main_menu_buttons_list) {
		elem := main_menu_buttons_list[i]
		elem.call(win, f32((i + 1) * 50) + 50, elem.data, g)
	}
}

draw_settings_menu_buttons :: proc(win: ^Window, g: ^Game_Memory) {
	for i in 0 ..< len(settings_buttons_list) {
		elem := settings_buttons_list[i]
		elem.call(win, f32((i + 1) * 50) + 50, elem.data, g)
	}
}

draw_volume_menu_buttons :: proc(win: ^Window, g: ^Game_Memory) {
	for i in 0 ..< len(volume_buttons_list) {
		elem := volume_buttons_list[i]
		elem.call(win, f32((i + 1) * 50) + 50, elem.data, g)
	}
}

draw_float_window :: proc(menu_window: ^Window) {
	rec := rl.Rectangle{menu_window.x, menu_window.y, menu_window.width, menu_window.height}

	rl.DrawText(
		"Main Menu",
		i32(get_relative_width_center(menu_window)) - 50,
		i32(get_relative_height_center(menu_window)) / 5,
		20,
		rl.BEIGE,
	)

	rl.DrawRectangleRounded(rec, 0.2, 3, rl.Fade(rl.BEIGE, 0.8))
}

draw_main_menu :: proc(g: ^Game_Memory) -> Window {
	width: f32 = f32(rl.GetScreenWidth()) / 1.8
	height: f32 = f32(rl.GetScreenHeight()) / 1.8
	x := f32(rl.GetScreenWidth()) / 2.0 - width / 2.0
	y := f32(rl.GetScreenHeight()) / 2.0 - height / 2.0
	//    menu_init()
	menu_window := Window{width, height, x, y}
	rl.DrawFPS(10, 10)
	rl.BeginDrawing()
	button_size(32)
	draw_background(g)
	draw_float_window(&menu_window)
	return menu_window
}
