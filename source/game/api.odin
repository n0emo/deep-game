package game

import rl "vendor:raylib"

game_memory: ^Game_Memory

@(export, link_name = "game_update")
api_update :: proc() {
	game_update(game_memory)
	game_draw(game_memory)

	// Everything on tracking allocator is valid until end-of-frame.
	free_all(context.temp_allocator)
}

@(export, link_name = "game_init_window")
api_init_window :: proc() {
	rl.SetConfigFlags({.WINDOW_RESIZABLE, .VSYNC_HINT})
	rl.InitWindow(1280, 720, "Odin + Raylib + Hot Reload template!")
	rl.SetWindowPosition(200, 200)
	rl.SetTargetFPS(500)
	rl.SetExitKey(nil)
}

@(export, link_name = "game_init")
api_init :: proc() {
	game_memory = game_make()
	api_hot_reloaded(game_memory)
}

@(export, link_name = "game_should_run")
api_should_run :: proc() -> bool {
	when ODIN_OS != .JS {
		if rl.WindowShouldClose() {
			return false
		}
	}

	return game_memory.run
}

@(export, link_name = "game_shutdown")
api_shutdown :: proc() {
	game_destroy(game_memory)
}

@(export, link_name = "game_shutdown_window")
api_shutdown_window :: proc() {
	rl.CloseWindow()
}

@(export, link_name = "game_memory")
api_memory :: proc() -> rawptr {
	return game_memory
}

@(export, link_name = "game_memory_size")
api_memory_size :: proc() -> int {
	return size_of(Game_Memory)
}

@(export, link_name = "game_hot_reloaded")
api_hot_reloaded :: proc(mem: rawptr) {
	game_memory = (^Game_Memory)(mem)
}

@(export, link_name = "game_force_reload")
api_force_reload :: proc() -> bool {
	return rl.IsKeyPressed(.F5)
}

@(export, link_name = "game_force_restart")
api_force_restart :: proc() -> bool {
	return rl.IsKeyPressed(.F6)
}
