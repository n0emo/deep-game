package game

import "../tiled"
import rl "vendor:raylib"

TILE_SIZE :: 16

Tile_Map :: struct {
	tilemap: ^tiled.Tilemap,
}

tilemap_make :: proc(tilemap: ^tiled.Tilemap) -> Tile_Map {
	return Tile_Map{tilemap = tilemap}
}


tilemap_destroy :: proc(m: ^Tile_Map) {
}

tilemap_get_base_tile :: proc(m: ^Tile_Map, x, y: u32) -> ^tiled.Tile {
	layer := &m.tilemap.layers[0]
	return &layer.tiles[layer.width * y + x]
}

tilemap_width :: proc(m: ^Tile_Map) -> u32 {
	return m.tilemap.layers[0].width
}

tilemap_height :: proc(m: ^Tile_Map) -> u32 {
	return m.tilemap.layers[0].height
}

tilemap_draw :: proc(m: ^Tile_Map, offset: rl.Vector2) {
	for x in 0 ..< tilemap_width(m) {
		for y in 0 ..< tilemap_height(m) {
			dest := rl.Rectangle {
				x      = offset.x + f32(x) * f32(TILE_SIZE),
				y      = offset.y + f32(y) * f32(TILE_SIZE),
				width  = TILE_SIZE,
				height = TILE_SIZE,
			}
			tile := tilemap_get_base_tile(m, x, y)
			rl.DrawTexturePro(tile.texture, tile.rect, dest, 0.0, 0.0, rl.WHITE)
		}
	}
}

Tile :: struct {
	texture:     rl.Texture2D,
	is_passable: bool,
}

tile_make :: proc(texture: rl.Texture2D, is_passable: bool) -> Tile {
	if texture.width != TILE_SIZE || texture.height != TILE_SIZE {
		// rl.TraceLog(
		// 	.ERROR,
		// 	"Incorrect tile size: (%dx%d), must be (%dx%d)",
		// 	texture.width,
		// 	texture.height,
		// 	i32(TILE_SIZE),
		// 	i32(TILE_SIZE),
		// )
	}
	return Tile{texture = texture, is_passable = is_passable}
}
