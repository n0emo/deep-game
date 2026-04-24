package game

import rl "vendor:raylib"

World :: struct {
	tilemap: Tile_Map,
	player:  Player,
}

world_make :: proc(assets: ^Assets) -> World {
	tilemap := tilemap_make(20, 20)
	for &tile in tilemap.tiles {
		tile = tile_make(assets.sprites.grass, true)
	}
	player := player_make(assets.sprites.player)
	return World{tilemap = tilemap, player = player}
}

world_destroy :: proc(w: ^World) {
	tilemap_destroy(&w.tilemap)
}

world_update :: proc(w: ^World) {
	player_update(&w.player)
}

world_draw :: proc(w: ^World) {
	tilemap_draw(&w.tilemap, rl.Vector2(0))
	player_draw(&w.player)
}
