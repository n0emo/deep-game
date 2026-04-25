package atlas

import "core:c"
import "core:encoding/json"
import "core:path/slashpath"
import "core:strings"
import rl "vendor:raylib"

Atlas :: struct {
	texture: rl.Texture2D,
	frames:  map[string]Frame,
}

load :: proc(path: string) -> (atlas: Atlas, error: json.Unmarshal_Error) {
	cpath := strings.clone_to_cstring(path, context.temp_allocator)
	data_size: c.int
	data := rl.LoadFileData(cpath, &data_size)
	defer rl.UnloadFileData(data)
	desc: Atlas_Descriptor
	json.unmarshal(data[:data_size], &desc, allocator = context.temp_allocator) or_return

	path_dir := slashpath.dir(path, context.temp_allocator)
	image_path := slashpath.join({path_dir, desc.meta.image}, context.temp_allocator)
	image_cpath := strings.clone_to_cstring(image_path, context.temp_allocator)
	atlas.texture = rl.LoadTexture(image_cpath)

	frames := make(map[string]Frame)
	for name, frame in desc.frames {
		frames[strings.clone(name)] = {
			frame              = rect_descriptor_to_raylib(frame.frame),
			rotated            = frame.rotated,
			trimmed            = frame.trimmed,
			sprite_source_size = rect_descriptor_to_raylib(frame.spriteSourceSize),
			source_size        = size_descriptor_to_raylib(frame.sourceSize),
			duration           = frame.duration,
		}
	}
	atlas.frames = frames

	return
}

unload :: proc(atlas: ^Atlas) {
	rl.UnloadTexture(atlas.texture)
	for name in atlas.frames {
		delete(name)
	}
	delete(atlas.frames)
}

Frame :: struct {
	frame:              rl.Rectangle,
	rotated:            bool,
	trimmed:            bool,
	sprite_source_size: rl.Rectangle,
	source_size:        rl.Vector2,
	duration:           f32,
}

@(private)
Atlas_Descriptor :: struct {
	frames: map[string]Frame_Descriptor,
	meta:   Meta_Descriptor,
}

Meta_Descriptor :: struct {
	app:     string,
	version: string,
	image:   string,
	format:  string,
	size:    Size_Descriptor,
	scale:   string,
}

@(private)
Frame_Descriptor :: struct {
	frame:            Rectangle_Descriptor,
	rotated:          bool,
	trimmed:          bool,
	spriteSourceSize: Rectangle_Descriptor,
	sourceSize:       Size_Descriptor,
	duration:         f32,
}

Rectangle_Descriptor :: struct {
	x: i32,
	y: i32,
	w: i32,
	h: i32,
}

Size_Descriptor :: struct {
	w: i32,
	h: i32,
}

@(private)
rect_descriptor_to_raylib :: proc(desc: Rectangle_Descriptor) -> rl.Rectangle {
	return {x = f32(desc.x), y = f32(desc.y), width = f32(desc.w), height = f32(desc.h)}
}

@(private)
size_descriptor_to_raylib :: proc(desc: Size_Descriptor) -> rl.Vector2 {
	return {f32(desc.w), f32(desc.h)}
}
