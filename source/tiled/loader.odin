package tiled

Loader :: struct {
	tilemaps: map[string]Tilemap,
	tilesets: map[string]Tileset,
}

loader_make :: proc() -> ^Loader {
	loader := new(Loader)
	loader.tilemaps = make(map[string]Tilemap)
	loader.tilesets = make(map[string]Tileset)
	return loader
}

loader_destroy :: proc(loader: ^Loader) {

	for _, &tilemap in loader.tilemaps {
		tilemap_unload(&tilemap)
	}

	for _, _ in loader.tilesets {
		// unload_tileset(&tileset)
	}
	free(loader)
}

