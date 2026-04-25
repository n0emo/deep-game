package tiled

import rl "vendor:raylib"

Tile :: struct {
	id:      u32,
	type:    string,
	texture: rl.Texture,
	rect:    rl.Rectangle,
}
