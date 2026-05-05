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
		case Tile_Layer_Descriptor:
			layer := Tile_Layer {
				id      = l_desc.id,
				x       = l_desc.x,
				y       = l_desc.y,
				width   = l_desc.width,
				
				height  = l_desc.height,
				name    = strings.clone(l_desc.name),
				class   = strings.clone(l_desc.class),
				opacity = l_desc.opacity,
				visible = l_desc.visible,
				tiles   = make([]Tile, len(l_desc.data)),
			}

			for tile_id, tile_index in l_desc.data {
				gid := tile_id & 0x0FFFFFFF
				if gid == 0 {
					continue
				}
				found := false
				for j := len(tilesets) - 1; j >= 0; j -= 1 {
					if gid >= tilesets[j].firstgit {
						id := gid - tilesets[j].firstgit
						tile, _ := tileset_get_tile(&tilesets[j].tileset, id)
						layer.tiles[tile_index] = tile
						found = true
						break
					}
				}
				if !found {
					error = Error_Unknown_Tileset {
						gid = tile_id,
					}
					return
				}
			}
			layers[layer_index] = layer

		case Object_Layer_Descriptor:
			layer := Object_Layer {
				id      = l_desc.id,
				x       = l_desc.x,
				y       = l_desc.y,
				width   = l_desc.width,
				height  = l_desc.height,
				name    = strings.clone(l_desc.name),
				class   = strings.clone(l_desc.class),
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
	height:     int,
	id:         int,
	name:       string,
	opacity:    int,
	point:      bool,
	rotation:   int,
	type:       string,
	visible:    bool,
	width:      int,
	x:          f32,
	y:          f32,
	properties: map[string]Object_Value,
}

Object_Value :: union {
	string,
	int,
}

Object_Layer :: struct {
	id:      u32,
	x:       u32,
	y:       u32,
	width:   u32,
	height:  u32,
	name:    string,
	class:   string,
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
	class:   string,
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
tilemap_descriptor_load :: proc(
	path: string,
) -> (
	desc: Tilemap_Descriptor,
	err: json.Unmarshal_Error,
) {
	cpath := strings.clone_to_cstring(path, context.temp_allocator)
	data_size: c.int
	data := rl.LoadFileData(cpath, &data_size)

	root_value, parse_err := json.parse(data[:data_size], spec = .JSON5)
	if parse_err != nil {
		err = .Invalid_Data
		return
	}

	root, ok := root_value.(json.Object)
	if !ok {
		err = .Invalid_Data
		return
	}

	if v, e := root["width"].(json.Float); e {desc.width = u32(v)}
	if v, e := root["height"].(json.Float); e {desc.height = u32(v)}
	if v, e := root["tilewidth"].(json.Float); e {desc.tilewidth = u32(v)}
	if v, e := root["tileheight"].(json.Float); e {desc.tileheight = u32(v)}
	if v, e := root["infinite"].(json.Boolean); e {desc.infinite = bool(v)}
	if v, e := root["type"].(json.String); e {desc.type = strings.clone(v)}
	if v, e := root["orientation"].(json.String); e {desc.orientation = strings.clone(v)}
	if v, e := root["renderorder"].(json.String); e {desc.renderorder = strings.clone(v)}
	if v, e := root["tiledversion"].(json.String); e {desc.tiledversion = strings.clone(v)}
	if v, e := root["version"].(json.String); e {desc.version = strings.clone(v)}

	if tilesets_val, e := root["tilesets"].(json.Array); e {
		desc.tilesets = make([]Tilemap_Descriptor_Tileset, len(tilesets_val))
		for val, i in tilesets_val {
			obj, obj_ok := val.(json.Object)
			if !obj_ok do continue
			if v, fe := obj["firstgid"].(json.Float); fe {
				desc.tilesets[i].firstgid = u32(v)
			}
			if v, fe := obj["source"].(json.String); fe {
				desc.tilesets[i].source = strings.clone(v)
			}
		}
	}

	if layers_val, e := root["layers"].(json.Array); e {
		layers := make(
			[dynamic]Tilemap_Descriptor_Layer,
			0,
			len(layers_val),
			context.temp_allocator,
		)

		for val in layers_val {
			obj, obj_ok := val.(json.Object)
			if !obj_ok do continue

			layer_type, _ := obj["type"].(json.String)

			switch layer_type {
			case "tilelayer":
				layer := Tile_Layer_Descriptor{}
				if v, fe := obj["id"].(json.Float); fe {layer.id = u32(v)}
				if v, fe := obj["x"].(json.Float); fe {layer.x = u32(v)}
				if v, fe := obj["y"].(json.Float); fe {layer.y = u32(v)}
				if v, fe := obj["width"].(json.Float); fe {layer.width = u32(v)}
				if v, fe := obj["height"].(json.Float); fe {layer.height = u32(v)}
				if v, fe := obj["opacity"].(json.Float); fe {layer.opacity = u32(v)}
				if v, fe := obj["name"].(json.String); fe {layer.name = strings.clone(v)}
				if v, fe := obj["class"].(json.String); fe {layer.class = strings.clone(v)}
				if v, fe := obj["type"].(json.String); fe {layer.type = strings.clone(v)}
				if v, fe := obj["visible"].(json.Boolean); fe {layer.visible = bool(v)}

				if data_arr, fe := obj["data"].(json.Array); fe {
					layer.data = make([]u32, len(data_arr))
					for d, di in data_arr {
						if iv, ie := d.(json.Float); ie {
							layer.data[di] = u32(iv)
						}
					}
				}
				append(&layers, Tilemap_Descriptor_Layer(layer))

			case "objectgroup":
				layer := Object_Layer_Descriptor{}
				if v, fe := obj["id"].(json.Float); fe {layer.id = u32(v)}
				if v, fe := obj["x"].(json.Float); fe {layer.x = u32(v)}
				if v, fe := obj["y"].(json.Float); fe {layer.y = u32(v)}
				if v, fe := obj["visible"].(json.Boolean); fe {layer.visible = bool(v)}
				if v, fe := obj["name"].(json.String); fe {layer.name = strings.clone(v)}
				if v, fe := obj["class"].(json.String); fe {layer.class = strings.clone(v)}

				if objs_arr, fe := obj["objects"].(json.Array); fe {
					layer.objects = make([]Object, len(objs_arr))
					for o, oi in objs_arr {
						oobj, ook := o.(json.Object)
						if !ook do continue
						if v, ie := oobj["id"].(json.Float); ie {layer.objects[oi].id = int(v)}
						if v, ie := oobj["x"].(json.Float); ie {layer.objects[oi].x = f32(v)}
						if v, ie := oobj["y"].(json.Float); ie {layer.objects[oi].y = f32(v)}
						if v, ie := oobj["width"].(json.Float);
						   ie {layer.objects[oi].width = int(v)}
						if v, ie := oobj["height"].(json.Float);
						   ie {layer.objects[oi].height = int(v)}
						if v, ie := oobj["name"].(json.String);
						   ie {layer.objects[oi].name = strings.clone(v)}
						if v, ie := oobj["type"].(json.String);
						   ie {layer.objects[oi].type = strings.clone(v)}
						if v, ie := oobj["visible"].(json.Boolean);
						   ie {layer.objects[oi].visible = bool(v)}
						if v, ie := oobj["point"].(json.Boolean);
						   ie {layer.objects[oi].point = bool(v)}
						if v, ie := oobj["rotation"].(json.Float);
						   ie {layer.objects[oi].rotation = int(v)}
						if v, ie := oobj["properties"].(json.Array); ie {
							layer.objects[oi].properties = make(map[string]Object_Value)
							props := &layer.objects[oi].properties
							for prop in v {
								prop_obj := prop.(json.Object) or_continue
								type := prop_obj["type"].(json.String) or_continue
								name := prop_obj["name"].(json.String) or_continue
								prop_val := prop_obj["value"]
								switch type {
								case "string":
									props[name] = prop_val.(json.String) or_continue
								case "int":
									props[name] = cast(int)prop_val.(json.Float) or_continue
								}
							}
						}
					}
				}
				append(&layers, Tilemap_Descriptor_Layer(layer))
			}
		}

		desc.layers = make([]Tilemap_Descriptor_Layer, len(layers))
		copy(desc.layers, layers[:])
	}

	return
}

@(private = "file")
tilemap_descriptor_unload :: proc(desc: ^Tilemap_Descriptor) {
	for &tileset in desc.tilesets {
		delete(tileset.source)
	}
	for l_desc in desc.layers {

		switch layer_desc in l_desc {
		case Tile_Layer_Descriptor:
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
	class:   string,
	opacity: u32,
	visible: bool,
	objects: []Object,
}

@(private = "file")
Tilemap_Descriptor_Layer :: union {
	Tile_Layer_Descriptor,
	Object_Layer_Descriptor,
}

@(private = "file")
Tile_Layer_Descriptor :: struct {
	data:    []u32,
	height:  u32,
	id:      u32,
	name:    string,
	class:   string,
	opacity: u32,
	type:    string,
	visible: bool,
	width:   u32,
	x:       u32,
	y:       u32,
}
