package game

import "core:math/linalg"
import rl "vendor:raylib"

CAMERA_LERP :: 0.05

World :: struct {
	tilemap: Tile_Map,
	player:  Player,
	camera:  rl.Camera2D,
}

world_make :: proc(assets: ^Assets) -> World {
	tilemap := tilemap_make(20, 20)
	for &tile in tilemap.tiles {
		tile = tile_make(assets.sprites.grass, true)
	}
	player := player_make(assets.sprites.player)
	camera := rl.Camera2D{}

	return World{tilemap = tilemap, player = player, camera = camera}
}

world_destroy :: proc(w: ^World) {
	tilemap_destroy(&w.tilemap)
}

world_update :: proc(w: ^World) {
	player_update(&w.player)
	world_update_camera(w)
}

world_draw :: proc(w: ^World) {
	rl.BeginMode2D(w.camera)
	tilemap_draw(&w.tilemap, rl.Vector2(0))
	player_draw(&w.player)
	rl.EndMode2D()
}

@(private = "file")
world_update_camera :: proc(w: ^World) {
	w.camera.zoom = 3.0
	w.camera.offset = rl.Vector2{f32(rl.GetScreenWidth()) * 0.5, f32(rl.GetScreenHeight()) * 0.5}
	w.camera.target = linalg.lerp(w.camera.target, w.player.pos, CAMERA_LERP)
}
