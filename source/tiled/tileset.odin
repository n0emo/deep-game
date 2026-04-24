package tiled

import "core:c"
import "core:encoding/json"
import "core:fmt"
import rl "vendor:raylib"

Tileset :: struct {
	using descriptor: Tileset_Descriptor,
	texture:          rl.Texture2D,
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

load_tileset :: proc(tilesets_dir: string, name: string) -> Tileset {
	desc: Tileset_Descriptor
	data_size: c.int
	data := rl.LoadFileData(fmt.ctprintf("%s/%s", tilesets_dir, name), &data_size)
	defer rl.UnloadFileData(data)
	err := json.unmarshal(data[:data_size], &desc)
	if err != nil {
		panic(fmt.tprintf("%v", err))
	}
	texture := rl.LoadTexture(fmt.ctprintf("%s/%s", tilesets_dir, desc.image))

	return Tileset{descriptor = desc, texture = texture}
}

unload_tileset :: proc(tileset: ^Tileset) {
	rl.UnloadTexture(tileset.texture)
}
