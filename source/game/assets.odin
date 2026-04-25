package game

import "core:fmt"
import "core:mem/virtual"
import rl "vendor:raylib"

Assets :: struct {
	arena:   virtual.Arena,
	sprites: Assets_Sprites,
}

assets_load :: proc(assets_dir: string = "assets") -> ^Assets {
	assets := new(Assets)
	context.allocator = virtual.arena_allocator(&assets.arena)
	assets.sprites = assets_sprites_load(fmt.tprintf("%s/%s", assets_dir, "sprites"))

	return assets
}

assets_unload :: proc(assets: ^Assets) {
	{
		context.allocator = virtual.arena_allocator(&assets.arena)
		assets_sprites_unload(&assets.sprites)
	}
	virtual.arena_destroy(&assets.arena)
	free(assets)
}

Assets_Sprites :: struct {
	player:    rl.Texture2D,
	grass:     rl.Texture2D,
	main_menu: rl.Texture2D,
	heart:     rl.Texture2D,
	shield:    rl.Texture2D,
}

@(private = "file")
assets_sprites_load :: proc(sprites_dir: string) -> Assets_Sprites {
	return Assets_Sprites {
		player = load_sprite(sprites_dir, "player.png"),
		grass = load_sprite(sprites_dir, "grass.png"),
		main_menu = load_sprite(sprites_dir, "main_menu.png"),
		heart = load_sprite(sprites_dir, "heart.png"),
		shield = load_sprite(sprites_dir, "shield.png"),
	}
}

@(private = "file")
assets_sprites_unload :: proc(sprites: ^Assets_Sprites) {
	rl.UnloadTexture(sprites.player)
	rl.UnloadTexture(sprites.grass)
	rl.UnloadTexture(sprites.main_menu)
	rl.UnloadTexture(sprites.heart)
	rl.UnloadTexture(sprites.shield)
}

@(private = "file")
load_sprite :: proc(sprites_dir: string, name: string) -> rl.Texture2D {
	return rl.LoadTexture(fmt.ctprintf("%s/%s", sprites_dir, name))
}
