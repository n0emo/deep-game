package game

import "core:fmt"
import rl "vendor:raylib"

PIXEL_WINDOW_HEIGHT :: 180

Game_Memory :: struct {
	assets:      ^Assets,
	world:       World,
	some_number: int,
	run:         bool,
	state:       Game_State,
}

Game_State :: enum {
	MENU,
	GAME,
	FIGHT,
	NEW_GAME,
	MENU_SETTINGS,
	MENU_SOUND,
	MENU_GRAPHICS,
	EXIT,
}

game_make :: proc() -> ^Game_Memory {
	g := new(Game_Memory)
	assets := assets_load()
	world := world_make(assets)

	g^ = Game_Memory {
		assets = assets,
		world  = world,
		run    = true,
		state  = Game_State.MENU,
	}
	return g
}

game_destroy :: proc(g: ^Game_Memory) {
	world_destroy(&g.world)
	assets_unload(g.assets)
	main_menu_destroy()

	free(g)
}

game_camera :: proc(g: ^Game_Memory) -> rl.Camera2D {
	w := f32(rl.GetScreenWidth())
	h := f32(rl.GetScreenHeight())

	return {zoom = h / PIXEL_WINDOW_HEIGHT, target = g.world.player.pos, offset = {w / 2, h / 2}}
}

ui_camera :: proc() -> rl.Camera2D {
	return {zoom = f32(rl.GetScreenHeight()) / PIXEL_WINDOW_HEIGHT}
}

game_update :: proc(g: ^Game_Memory) {
	world_update(&g.world)
	if rl.IsKeyPressed(.ESCAPE) {
		g.run = false
	}
}

game_start :: proc(g: ^Game_Memory) {
	world_draw(&g.world)
	g.state = Game_State.GAME
}

game_menu :: proc(g: ^Game_Memory) {
	if len(element_list.main_menu_buttons_list) == 0 {
		main_menu_init()
	}
	menu_window := draw_main_menu(g)
	draw_main_menu_buttons(&menu_window, g, &element_list)
	//g.state = Game_State.MENU
}

game_hud :: proc(g: ^Game_Memory) {
	//hud_init()
	draw_hud(g)
	//g.state = Game_State.FIGHT
}

game_draw :: proc(g: ^Game_Memory) {

	rl.BeginDrawing()
	rl.ClearBackground(rl.SKYBLUE)
	rl.BeginMode2D(game_camera(g))
	rl.EndMode2D()

	rl.BeginMode2D(ui_camera())

	rl.DrawText(fmt.ctprintf("player_pos: %v", g.world.player.pos), 5, 5, 8, rl.WHITE)
	switch g.state {
	case .MENU:
		game_menu(g)
	case .GAME:
		game_start(g)
	case .FIGHT:
		game_hud(g)
	case .MENU_SETTINGS:
		menu_window := draw_main_menu(g)
		draw_settings_menu_buttons(&menu_window, g, &element_list)
	case .NEW_GAME:
	case .MENU_SOUND:
		menu_window := draw_main_menu(g)
		draw_volume_menu_buttons(&menu_window, g, &element_list)
	case .MENU_GRAPHICS:
		menu_window := draw_main_menu(g)
		draw_graphics_menu_buttons(&menu_window, g, &element_list)
	case .EXIT:
		g.run = false
	}
	// #partial switch s in screen {
	// case Pause:
	// 	if s == .Exit {
	// 		g.run = false
	// 	}
	// 	if s != .Continue {
	// 		menu()
	// 	}
	// case Settings:
	// 	menu()
	// }
	rl.EndMode2D()

	rl.EndDrawing()

}

game_parent_window_size_changed :: proc(w, h: int) {
	rl.SetWindowSize(i32(w), i32(h))
}
