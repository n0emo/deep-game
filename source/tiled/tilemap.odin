package tiled

import "core:c"
import "core:encoding/json"
import "core:strings"
import rl "vendor:raylib"

Tilemap :: struct {}

tilemap_load :: proc(loader: ^Loader) -> Tilemap {
	return Tilemap{}
}

tilemap_unload :: proc(tilemap: ^Tilemap) {}


Tilemap_Descriptor :: struct {
	type:             string,
	infinite:         bool,
	width:            u32,
	height:           u32,
	tileheight:       u32,
	tilewidth:        u32,
	orientation:      string,
	renderorder:      string,
	layers:           Tilemap_Descriptor_Layer,
	nextlayerid:      u32,
	nextobjectid:     u32,
	tilesets:         Tilemap_Descriptor_Tileset,
	compressionlevel: i32,
	tiledversion:     string,
	version:          string,
}

tilemap_descriptor_load :: proc(path: string) -> (Tilemap_Descriptor, json.Unmarshal_Error) {
	cpath := strings.clone_to_cstring(path, context.temp_allocator)
	data_size: c.int
	data := rl.LoadFileData(cpath, &data_size)
	desc: Tilemap_Descriptor
	err := json.unmarshal(data[:data_size], &desc)
	if err != nil {
		return Tilemap_Descriptor{}, err
	}
	return desc, nil
}

Tilemap_Descriptor_Tileset :: struct {
	firstgid: u32,
	source:   string,
}

Tilemap_Descriptor_Layer :: struct {
	data:    []u32,
	height:  u32,
	id:      u32,
	name:    string,
	opacity: u32,
	type:    string,
	visible: bool,
	width:   u32,
	x:       u32,
	y:       u32,
}
