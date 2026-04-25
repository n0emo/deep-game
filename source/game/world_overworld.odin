package game

import atlas "../atlas"
import "core:math/linalg"
import rl "vendor:raylib"

CAMERA_LERP :: 0.05

World_Overworld :: struct {
	tilemap: Tile_Map,
	player:  Overworld_Player,
	camera:  rl.Camera2D,
}

world_overworld_make :: proc(assets: ^Assets) -> World_Overworld {
	tilemap := tilemap_make(&assets.tilemap_level_1)
	player := player_make(&assets.sprites.player)
	camera := rl.Camera2D{}

	return {tilemap = tilemap, player = player, camera = camera}
}

world_overworld_destroy :: proc(w: ^World_Overworld) {
	tilemap_destroy(&w.tilemap)
}

world_overworld_update :: proc(w: ^World_Overworld) {
	player_update(&w.player)
	world_update_camera(w)
}

world_overworld_draw :: proc(w: ^World_Overworld) {
	rl.ClearBackground(rl.SKYBLUE)
	rl.BeginMode2D(w.camera)
	tilemap_draw(&w.tilemap, rl.Vector2(0))
	player_draw(&w.player)
	rl.EndMode2D()
}

world_overworld_ui :: proc(w: ^World_Overworld, queue: ^Event_Queue) {}

world_overworld_handle_event :: proc(w: ^World_Overworld, event: Event) {}

@(private = "file")
Overworld_Player :: struct {
	pos:       rl.Vector2,
	animation: Animation,
}

@(private = "file")
player_make :: proc(atlas: ^atlas.Atlas) -> Overworld_Player {
	animation := animation_make(
		atlas.texture,
		{
			animation_frame_from_atlas(atlas, "player-idle-front-0"),
			animation_frame_from_atlas(atlas, "player-idle-front-1"),
			animation_frame_from_atlas(atlas, "player-idle-front-2"),
			animation_frame_from_atlas(atlas, "player-idle-front-3"),
		},
	)
	return Overworld_Player{pos = rl.Vector2(0), animation = animation}
}

@(private = "file")
player_update :: proc(player: ^Overworld_Player) {
	animation_update(&player.animation)
	input: rl.Vector2

	if rl.IsKeyDown(.UP) || rl.IsKeyDown(.W) {
		input.y -= 1
	}
	if rl.IsKeyDown(.DOWN) || rl.IsKeyDown(.S) {
		input.y += 1
	}
	if rl.IsKeyDown(.LEFT) || rl.IsKeyDown(.A) {
		input.x -= 1
	}
	if rl.IsKeyDown(.RIGHT) || rl.IsKeyDown(.D) {
		input.x += 1
	}

	input = linalg.normalize0(input)
	player.pos += input * rl.GetFrameTime() * 100
}

@(private = "file")
player_draw :: proc(player: ^Overworld_Player) {
	animation_draw(&player.animation, player.pos)
}

@(private = "file")
world_update_camera :: proc(w: ^World_Overworld) {
	w.camera.zoom = 4.0
	w.camera.offset = rl.Vector2{f32(rl.GetScreenWidth()) * 0.5, f32(rl.GetScreenHeight()) * 0.5}
	w.camera.target = linalg.lerp(w.camera.target, w.player.pos, CAMERA_LERP)
}
