package tiled

import "base:runtime"
import "core:c"
import "core:encoding/json"
import "core:path/slashpath"
import "core:strings"
import rl "vendor:raylib"

Tileset :: struct {
	texture:     rl.Texture2D,
	name:        string,
	imageheight: u32,
	imagewidth:  u32,
	margin:      u32,
	spacing:     u32,
	tilecount:   u32,
	tileheight:  u32,
	tilewidth:   u32,
	tiles:       []Tile,
}

Tileset_Load_Error :: union {
	json.Unmarshal_Error,
	runtime.Allocator_Error,
}

tileset_load :: proc(
	loader: ^Loader,
	path: string,
) -> (
	tileset: Tileset,
	error: Tileset_Load_Error,
) {
	desc := tileset_descriptor_load(path) or_return
	defer tileset_descriptor_unload(&desc)
	if t, ok := loader.tilesets[desc.name]; ok {
		return t, nil
	} else {
		if err := tileset_read_descriptor(&desc, &tileset); err != nil {
			return Tileset{}, err
		}

		texture, err := load_image_for_tileset(path, desc.image)
		if err != nil {
			delete(tileset.name)
			return Tileset{}, err
		}
		tileset.texture = texture

		tileset.tiles = make([]Tile, desc.tilecount)
		for tile in desc.tiles {
			tileset.tiles[tile.id] = {
				id      = tile.id,
				type    = strings.clone(tile.type),
				texture = texture,
				rect    = tileset_get_tile_rect(&tileset, tile.id),
			}
		}

		loader.tilesets[desc.name] = tileset
		return tileset, nil
	}
}

tileset_get_tile :: proc(tileset: ^Tileset, id: u32) -> (tile: Tile, ok: bool) {
	if int(id) < len(tileset.tiles) {
		return tileset.tiles[id], true
	} else {
		return Tile{}, false
	}
}

@(private = "file")
tileset_read_descriptor :: proc(
	desc: ^Tileset_Descriptor,
	tileset: ^Tileset,
) -> (
	error: Tileset_Load_Error,
) {
	tileset.name = strings.clone(desc.name)
	tileset.imageheight = desc.imageheight
	tileset.imagewidth = desc.imagewidth
	tileset.margin = desc.margin
	tileset.spacing = desc.spacing
	tileset.tilecount = desc.tilecount
	tileset.tileheight = desc.tileheight
	tileset.tilewidth = desc.tilewidth

	return nil
}

// TODO: handle spacing, margin, etc
@(private = "file")
tileset_get_tile_rect :: proc(tileset: ^Tileset, id: u32) -> rl.Rectangle {
	tiles_width := tileset.imagewidth / tileset.tilewidth
	x := id % tiles_width
	y := id / tiles_width
	return {
		x = f32(x * tileset.tilewidth),
		y = f32(y * tileset.tileheight),
		width = f32(tileset.tilewidth),
		height = f32(tileset.tileheight),
	}
}

@(private = "file")
load_image_for_tileset :: proc(
	path: string,
	image_name: string,
) -> (
	texture: rl.Texture2D,
	error: runtime.Allocator_Error,
) {
	image_dir := slashpath.dir(path, context.temp_allocator)
	image_path := slashpath.join({image_dir, image_name}, context.temp_allocator)
	image_cpath := strings.clone_to_cstring(image_path, context.temp_allocator)
	return rl.LoadTexture(image_cpath), nil
}

Tileset_Descriptor :: struct {
	image:       string,
	imageheight: u32,
	imagewidth:  u32,
	margin:      u32,
	name:        string,
	spacing:     u32,
	tilecount:   u32,
	tileheight:  u32,
	tilewidth:   u32,
	tiles:       []Tile_Descriptor,
}

Tile_Descriptor :: struct {
	id:   u32,
	type: string,
}

@(private = "file")
tileset_descriptor_load :: proc(
	path: string,
) -> (
	desc: Tileset_Descriptor,
	error: json.Unmarshal_Error,
) {
	data_size: c.int
	data := rl.LoadFileData(strings.clone_to_cstring(path, context.temp_allocator), &data_size)
	defer rl.UnloadFileData(data)
	json.unmarshal(data[:data_size], &desc) or_return
	return
}

@(private = "file")
tileset_descriptor_unload :: proc(desc: ^Tileset_Descriptor) {
	for &tile in desc.tiles {
		delete(tile.type)
	}
	delete(desc.tiles)
	delete(desc.image)
	delete(desc.name)
}
