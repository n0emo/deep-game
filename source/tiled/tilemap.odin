package tiled

import "base:runtime"
import "core:c"
import "core:encoding/json"
import "core:path/slashpath"
import "core:strings"
import rl "vendor:raylib"

Tilemap :: struct {
	width:      u32,
	height:     u32,
	tileheight: u32,
	tilewidth:  u32,
	layers:     []Tilemap_Layer,
}

Tilemap_Load_Error :: union {
	runtime.Allocator_Error,
	json.Unmarshal_Error,
	Tileset_Load_Error,
	Error_Unknown_Tileset,
}

Error_Unknown_Tileset :: struct {
	gid: u32,
}

tilemap_load :: proc(
	loader: ^Loader,
	path: string,
) -> (
	tilemap: Tilemap,
	error: Tilemap_Load_Error,
) {
	desc := tilemap_descriptor_load(path) or_return

	tilemap.width = desc.width
	tilemap.height = desc.height
	tilemap.tilewidth = desc.tilewidth
	tilemap.tileheight = desc.tileheight

	tilesets := make([]Tilemap_Tileset, len(desc.tilesets), context.temp_allocator)
	for &tileset_desc, i in desc.tilesets {
		tilemap_dir := slashpath.dir(path, context.temp_allocator)
		tileset_path := slashpath.join({tilemap_dir, tileset_desc.source}, context.temp_allocator)
		tileset := tileset_load(loader, tileset_path) or_return
		tilesets[i] = Tilemap_Tileset {
			firstgit = tileset_desc.firstgid,
			tileset  = tileset,
		}
	}

	layers := make([]Tilemap_Layer, len(desc.layers), context.temp_allocator)
	for layer_desc, layer_index in desc.layers {
		switch l_desc in layer_desc {
		case Tile_Descriptor_Layer:
			layer := Tile_Layer {
				id      = l_desc.id,
				x       = l_desc.x,
				y       = l_desc.y,
				width   = l_desc.width,
				height  = l_desc.height,
				name    = strings.clone(l_desc.name),
				opacity = l_desc.opacity,
				visible = l_desc.visible,
				tiles   = make([]Tile, len(l_desc.data)),
			}

			for tile_id, tile_index in l_desc.data {
				gid := tile_id & 0x0FFFFFFF
				for j in 0 ..< len(tilesets) {
					if (gid >= tilesets[j].firstgit) {
						id := gid - tilesets[j].firstgit
						tile, _ := tileset_get_tile(&tilesets[j].tileset, id)
						layer.tiles[tile_index] = tile
						break
					} else {
						error = Error_Unknown_Tileset {
							gid = tile_id,
						}
						return
					}
				}
				layers[layer_index] = layer
			}
		case Object_Layer_Descriptor:
			layer := Object_Layer {
				id      = l_desc.id,
				x       = l_desc.x,
				y       = l_desc.y,
				width   = l_desc.width,
				height  = l_desc.height,
				name    = strings.clone(l_desc.name),
				opacity = l_desc.opacity,
				visible = l_desc.visible,
				objects = make([]Object, 0),
			}
			layer.objects = l_desc.objects
			layers[layer_index] = layer
		}

	}
	tilemap.layers = make([]Tilemap_Layer, len(desc.layers))
	copy(tilemap.layers, layers)

	return
}


tilemap_unload :: proc(tilemap: ^Tilemap) {}

Tilemap_Tileset :: struct {
	firstgit: u32,
	tileset:  Tileset,
}

Tilemap_Layer :: union {
	Object_Layer,
	Tile_Layer,
}

Object :: struct {
	height:   int,
	id:       int,
	name:     string,
	opacity:  int,
	point:    bool,
	rotation: int,
	type:     string,
	visible:  bool,
	width:    int,
	x:        f32,
	y:        f32,
}

Object_Layer :: struct {
	id:      u32,
	x:       u32,
	y:       u32,
	width:   u32,
	height:  u32,
	name:    string,
	opacity: u32,
	visible: bool,
	objects: []Object,
}

Tile_Layer :: struct {
	id:      u32,
	x:       u32,
	y:       u32,
	width:   u32,
	height:  u32,
	name:    string,
	opacity: u32,
	visible: bool,
	tiles:   []Tile,
}

@(private = "file")
Tilemap_Descriptor :: struct {
	type:             string,
	infinite:         bool,
	width:            u32,
	height:           u32,
	tileheight:       u32,
	tilewidth:        u32,
	orientation:      string,
	renderorder:      string,
	layers:           []Tilemap_Descriptor_Layer,
	nextlayerid:      u32,
	nextobjectid:     u32,
	tilesets:         []Tilemap_Descriptor_Tileset,
	compressionlevel: i32,
	tiledversion:     string,
	version:          string,
}

@(private = "file")
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

@(private = "file")
tilemap_descriptor_unload :: proc(desc: ^Tilemap_Descriptor) {
	for &tileset in desc.tilesets {
		delete(tileset.source)
	}
	for l_desc in desc.layers {

		switch layer_desc in l_desc {
		case Tile_Descriptor_Layer:
			for &tile_id in layer_desc.data {
				_ = tile_id
			}
			delete(layer_desc.data)
			delete(layer_desc.name)
			delete(layer_desc.type)
		case Object_Layer_Descriptor:
			for &object in layer_desc.objects {
				delete(object.name)
				delete(object.type)
			}
		}

		delete(desc.type)
		delete(desc.orientation)
		delete(desc.renderorder)
		delete(desc.tiledversion)
		delete(desc.version)
	}
}

@(private = "file")
Tilemap_Descriptor_Tileset :: struct {
	firstgid: u32,
	source:   string,
}


@(private = "file")
Object_Layer_Descriptor :: struct {
	id:      u32,
	x:       u32,
	y:       u32,
	width:   u32,
	height:  u32,
	name:    string,
	opacity: u32,
	visible: bool,
	objects: []Object,
}

@(private = "file")
Tilemap_Descriptor_Layer :: union {
	Tile_Descriptor_Layer,
	Object_Layer_Descriptor,
}

@(private = "file")
Tile_Descriptor_Layer :: struct {
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
