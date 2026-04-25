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

@(private = "file")
layer_get_tile :: proc(m: ^tiled.Tile_Layer, x, y: u32) -> ^tiled.Tile {
	return &m.tiles[m.width * y + x]
}

tilemap_width :: proc(m: ^Tile_Map) -> u32 {
	return m.tilemap.width
}

tilemap_height :: proc(m: ^Tile_Map) -> u32 {
	return m.tilemap.height
}

tilemap_draw :: proc(m: ^Tile_Map, offset: rl.Vector2) {
	for layer in m.tilemap.layers {
		switch &l in layer {
		case tiled.Tile_Layer:
			for x in 0 ..< tilemap_width(m) {
				for y in 0 ..< tilemap_height(m) {
					dest := rl.Rectangle {
						x      = offset.x + f32(x) * f32(TILE_SIZE),
						y      = offset.y + f32(y) * f32(TILE_SIZE),
						width  = TILE_SIZE,
						height = TILE_SIZE,
					}
					tile := layer_get_tile(&l, x, y)
					rl.DrawTexturePro(tile.texture, tile.rect, dest, 0.0, 0.0, rl.WHITE)
				}
			}

		case tiled.Object_Layer:
			for obj in l.objects {
				dest := rl.Rectangle {
					x      = offset.x + obj.x,
					y      = offset.y + obj.y,
					width  = cast(f32)obj.width + 1,
					height = cast(f32)obj.height + 1,
				}
				rl.DrawRectangleLinesEx(dest, 1.0, rl.RED)
			}
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
