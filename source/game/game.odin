package game

import "core:fmt"
import rl "vendor:raylib"

PIXEL_WINDOW_HEIGHT :: 180

Game_Memory :: struct {
	assets:      ^Assets,
	world:       World,
	some_number: int,
	run:         bool,
}

game_make :: proc() -> ^Game_Memory {
	g := new(Game_Memory)
	assets := assets_load()
	world := world_make(assets)

	g^ = Game_Memory {
		assets = assets,
		world  = world,
		run    = true,
	}

	return g
}

game_destroy :: proc(g: ^Game_Memory) {
	world_destroy(&g.world)
	assets_unload(g.assets)
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
		//	g.run = false
		if screen != .Pause {
			screen = Pause.Pause
		} else {
			screen = Pause.Continue
		}
	}
}


game_draw :: proc(g: ^Game_Memory) {

	rl.BeginDrawing()
	rl.ClearBackground(rl.SKYBLUE)
	rl.BeginMode2D(game_camera(g))
	world_draw(&g.world)
	rl.EndMode2D()

	rl.BeginMode2D(ui_camera())

	rl.DrawText(fmt.ctprintf("player_pos: %v", g.world.player.pos), 5, 5, 8, rl.WHITE)

	#partial switch s in screen {
	case Pause:
		if s == .Exit {
			g.run = false
		}
		if s != .Continue {
			menu()
		}
	case Settings:
		menu()
	}

	rl.EndMode2D()

	rl.EndDrawing()

}

game_parent_window_size_changed :: proc(w, h: int) {
	rl.SetWindowSize(i32(w), i32(h))
}
