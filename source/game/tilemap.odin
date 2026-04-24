package game

import rl "vendor:raylib"

Tile_Map :: struct {
	tiles:  []Tile,
	width:  u32,
	height: u32,
}

tilemap_make :: proc(width, height: u32) -> Tile_Map {
	return Tile_Map{tiles = make([]Tile, width * height), width = width, height = height}
}

tilemap_get :: proc(m: ^Tile_Map, x, y: u32) -> ^Tile {
	assert(x < m.width)
	assert(y < m.height)
	return &m.tiles[y * m.width + x]
}

tilemap_destroy :: proc(m: ^Tile_Map) {
	delete(m.tiles)
}

Tile :: struct {
	image:       rl.Texture2D,
	is_passable: bool,
}
