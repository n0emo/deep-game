package game

import rl "vendor:raylib"

TILE_SIZE :: 16

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

tilemap_draw :: proc(m: ^Tile_Map, offset: rl.Vector2) {
	for x in 0 ..< m.width {
		for y in 0 ..< m.height {
			pos := rl.Vector2 {
				offset.x + f32(x) * f32(TILE_SIZE),
				offset.y + f32(y) * f32(TILE_SIZE),
			}
			tile := tilemap_get(m, x, y)
			rl.DrawTextureV(tile.texture, pos, rl.WHITE)
		}
	}
}

Tile :: struct {
	texture:     rl.Texture2D,
	is_passable: bool,
}

tile_make :: proc(texture: rl.Texture2D, is_passable: bool) -> Tile {
	if texture.width != TILE_SIZE || texture.height != TILE_SIZE {
		rl.TraceLog(
			.ERROR,
			"Incorrect tile size: (%dx%d), must be (%dx%d)",
			texture.width,
			texture.height,
			i32(TILE_SIZE),
			i32(TILE_SIZE),
		)
	}
	return Tile{texture = texture, is_passable = is_passable}
}
