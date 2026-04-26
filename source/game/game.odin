package game

import "core:fmt"
import rl "vendor:raylib"

PIXEL_WINDOW_HEIGHT :: 180

Game_Memory :: struct {
	assets:      ^Assets,
	state:       Game_State,
	world:       World,
	main_menu:   Main_Menu,
	event_queue: Event_Queue,
	input:       Input,
	audio:       Audio_System,
}

Game_State :: enum {
	Exit,
	Menu,
	Game,
}

game_make :: proc() -> ^Game_Memory {
	g := new(Game_Memory)

	event_queue := Event_Queue {
		queue = make([dynamic]Event),
	}
	assets := assets_load()
	main_menu := main_menu_make(assets)
	input := input_make()
	audio := audio_system_make(assets)


	g^ = Game_Memory {
		assets      = assets,
		main_menu   = main_menu,
		state       = .Menu,
		event_queue = event_queue,
		input       = input,
		audio       = audio,
	}

	event_dispatch(&g.event_queue, Event_Menu{})

	return g
}

game_destroy :: proc(g: ^Game_Memory) {
	assets_unload(g.assets)

	free(g)
}

ui_camera :: proc() -> rl.Camera2D {
	return {zoom = f32(rl.GetScreenHeight()) / PIXEL_WINDOW_HEIGHT}
}

game_update :: proc(g: ^Game_Memory) {
	input_update(&g.input, &g.event_queue)
	audio_system_update(&g.audio)

	for {
		event := event_pop(&g.event_queue) or_break
		rl.TraceLog(.DEBUG, "%s", fmt.tprint(event))
		game_handle_event(g, event)
	}

	switch g.state {
	case .Exit:
	case .Menu:
	case .Game:
		world_update(&g.world, &g.event_queue)
	}
}

game_handle_event :: proc(g: ^Game_Memory, event: Event) {
	audio_system_handle_event(&g.audio, event)

	#partial switch e in event {
	case Event_Exit:
		g.state = .Exit
	case Event_Start_Game:
		g.state = .Game
		g.world = world_make(g.assets)
	case Event_Menu:
		g.state = .Menu
	}

	switch g.state {
	case .Exit:
	case .Game:
		world_handle_event(&g.world, event)
	case .Menu:
		main_menu_handle_event(&g.main_menu, event)
	}
}

game_draw :: proc(g: ^Game_Memory) {
	rl.BeginDrawing()

	switch g.state {
	case .Exit:
	case .Menu:
	case .Game:
		world_draw(&g.world)
	}

	switch g.state {
	case .Exit:
	case .Menu:
		main_menu_ui(&g.main_menu, &g.event_queue)
	case .Game:
		world_ui(&g.world, &g.event_queue)
	}

	rl.DrawFPS(10, 10)

	rl.EndDrawing()
}

game_parent_window_size_changed :: proc(w, h: int) {
	rl.SetWindowSize(i32(w), i32(h))
}
