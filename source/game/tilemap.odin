package game

import "../tiled"
import rl "vendor:raylib"

TILE_SIZE :: 16

Tile_Map :: struct {
	tilemap:    ^tiled.Tilemap,
	base_layer: ^tiled.Tile_Layer,
	prop_layer: ^tiled.Tile_Layer,
	obj_layer:  ^tiled.Object_Layer,
	objects:    map[int]Object,
	spawnpoint: Object,
}

tilemap_make :: proc(tilemap: ^tiled.Tilemap) -> (tm: Tile_Map, ok: bool) {
	tm.tilemap = tilemap
	tm.base_layer = find_tile_layer(tilemap, "base") or_return
	tm.prop_layer = find_tile_layer(tilemap, "prop") or_return
	tm.obj_layer = find_obj_layer(tilemap, "object") or_return
	tm.objects = make(map[int]Object, len(tm.obj_layer.objects))
	for obj, i in tm.obj_layer.objects {
		tm.objects[obj.id] = object_make(obj)
		if _, is_sp := tm.objects[i].properties.(Object_Spawnpoint); is_sp {
			tm.spawnpoint = tm.objects[i]
		}
	}
	return tm, true
}

tilemap_destroy :: proc(m: ^Tile_Map) {
	delete(m.objects)
}

tilemap_width :: proc(m: ^Tile_Map) -> u32 {
	return m.tilemap.width
}

tilemap_height :: proc(m: ^Tile_Map) -> u32 {
	return m.tilemap.height
}

tilemap_draw :: proc(m: ^Tile_Map, offset: rl.Vector2) {
	draw_tile_layer(m, m.base_layer, offset)
	draw_tile_layer(m, m.prop_layer, offset)
	draw_obj_layer(m, m.obj_layer, offset)
}

tilemap_tile_passable :: proc(m: ^Tile_Map, tile: [2]i32) -> bool {
	if tile.x < 0 ||
	   tile.x >= i32(tilemap_width(m)) ||
	   tile.y < 0 ||
	   tile.y >= i32(tilemap_height(m)) {
		return false
	}

	tile := layer_get_tile(m.base_layer, u32(tile.x), u32(tile.y))
	return tile.type == "terrain"
}

tilemap_is_collides_with_object :: proc(
	m: ^Tile_Map,
	rect: rl.Rectangle,
) -> (
	obj: Object,
	ok: bool,
) {
	for _, o in m.objects {
		o_rect := rl.Rectangle{o.x, o.y, o.width, o.height}
		if rl.CheckCollisionRecs(rect, o_rect) {
			return o, true
		}
	}
	return Object{}, false
}

tilemap_delete_object :: proc(m: ^Tile_Map, id: int) {
	if id in m.objects {
		delete_key(&m.objects, id)
		for &o in m.obj_layer.objects {
			if o.id == id {
				o.visible = false
				break
			}
		}
	}
}

@(private = "file")
draw_tile_layer :: proc(m: ^Tile_Map, l: ^tiled.Tile_Layer, offset: rl.Vector2) {
	for x in 0 ..< tilemap_width(m) {
		for y in 0 ..< tilemap_height(m) {
			dest := rl.Rectangle {
				x      = offset.x + f32(x) * f32(TILE_SIZE),
				y      = offset.y + f32(y) * f32(TILE_SIZE),
				width  = TILE_SIZE,
				height = TILE_SIZE,
			}
			tile := layer_get_tile(l, x, y)
			rl.DrawTexturePro(tile.texture, tile.rect, dest, 0.0, 0.0, rl.WHITE)
		}
	}
}

@(private = "file")
draw_obj_layer :: proc(m: ^Tile_Map, l: ^tiled.Object_Layer, offset: rl.Vector2) {
	for obj in l.objects {
		if !obj.visible {
			continue
		}

		dest := rl.Rectangle {
			x      = offset.x + obj.x,
			y      = offset.y + obj.y,
			width  = cast(f32)obj.width + 1,
			height = cast(f32)obj.height + 1,
		}
		rl.DrawRectangleLinesEx(dest, 1.0, rl.RED)
	}
}

@(private = "file")
find_tile_layer :: proc(
	tilemap: ^tiled.Tilemap,
	class: string,
) -> (
	layer: ^tiled.Tile_Layer,
	ok: bool,
) {
	for &layer in tilemap.layers {
		tile_layer := (&layer.(tiled.Tile_Layer)) or_continue
		if tile_layer.class == class {
			return tile_layer, true
		}
	}
	return nil, false
}

@(private = "file")
find_obj_layer :: proc(
	tilemap: ^tiled.Tilemap,
	class: string,
) -> (
	layer: ^tiled.Object_Layer,
	ok: bool,
) {
	for &layer in tilemap.layers {
		tile_layer := (&layer.(tiled.Object_Layer)) or_continue
		if tile_layer.class == class {
			return tile_layer, true
		}
	}
	return nil, false
}

@(private = "file")
layer_get_tile :: proc(layer: ^tiled.Tile_Layer, x, y: u32) -> ^tiled.Tile {
	return &layer.tiles[layer.width * y + x]
}
