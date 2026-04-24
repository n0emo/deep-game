package game

import "core:fmt"
import rl "vendor:raylib"

Assets :: struct {
	sprites: Assets_Sprites,
}

Assets_Sprites :: struct {
	player: rl.Texture2D,
	grass:  rl.Texture2D,
}

assets_load :: proc(assets_dir: string = "assets") -> Assets {
	sprites := assets_sprites_load(fmt.tprintf("%s/%s", assets_dir, "sprites"))

	return Assets{sprites = sprites}
}

assets_unload :: proc(assets: ^Assets) {
	assets_sprites_unload(&assets.sprites)
}

@(private = "file")
assets_sprites_load :: proc(sprites_dir: string) -> Assets_Sprites {
	return Assets_Sprites {
		player = load_sprite(sprites_dir, "player.png"),
		grass = load_sprite(sprites_dir, "grass.png"),
	}
}

@(private = "file")
assets_sprites_unload :: proc(sprites: ^Assets_Sprites) {
	rl.UnloadTexture(sprites.player)
	rl.UnloadTexture(sprites.grass)
}

@(private = "file")
load_sprite :: proc(sprites_dir: string, name: string) -> rl.Texture2D {
	return rl.LoadTexture(fmt.ctprintf("%s/%s", sprites_dir, name))
}
