package tiled

import "base:runtime"
import "core:mem/virtual"

Loader :: struct {
	arena:    virtual.Arena,
	tilemaps: map[string]Tilemap,
	tilesets: map[string]Tileset,
}

loader_make :: proc() -> ^Loader {
	loader := new(Loader)
	loader.arena = virtual.Arena{}
	context.allocator = virtual.arena_allocator(&loader.arena)
	loader.tilemaps = make(map[string]Tilemap)
	loader.tilesets = make(map[string]Tileset)
	return loader
}

loader_destroy :: proc(loader: ^Loader) {
	{
		context.allocator = virtual.arena_allocator(&loader.arena)

		for name, &tilemap in loader.tilemaps {
		}

		for name, &tileset in loader.tilesets {
			unload_tileset(&tileset)
		}
	}
	virtual.arena_destroy(&loader.arena)
	free(loader)
}
