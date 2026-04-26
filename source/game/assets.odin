package game

import "../atlas"
import "../tiled"
import "core:fmt"
import "core:path/slashpath"
import "core:strings"
import rl "vendor:raylib"

Assets :: struct {
	sprites:         Assets_Sprites,
	audio:           Assets_Audio,
	tiled_loader:    ^tiled.Loader,
	tilemap_level_1: tiled.Tilemap,
}

assets_load :: proc(assets_dir: string = "assets") -> ^Assets {
	assets := new(Assets)
	assets.sprites = assets_sprites_load(fmt.tprintf("%s/%s", assets_dir, "sprites"))
	assets.audio = assets_audio_load(slashpath.join({assets_dir, "audio"}, context.temp_allocator))
	assets.tiled_loader = tiled.loader_make()
	tilemap_level_1, _ := tiled.tilemap_load(assets.tiled_loader, "./assets/tilemaps/level-1.tmj")
	for _, tileset in assets.tiled_loader.tilesets {
		rl.SetTextureFilter(tileset.texture, .POINT)
	}
	assets.tilemap_level_1 = tilemap_level_1

	return assets
}

assets_unload :: proc(assets: ^Assets) {
	assets_sprites_unload(&assets.sprites)
	assets_audio_unload(&assets.audio)
	tiled.loader_destroy(assets.tiled_loader)
	free(assets)
}

Assets_Sprites :: struct {
	player:    atlas.Atlas,
	grass:     rl.Texture2D,
	main_menu: rl.Texture2D,
	heart:     rl.Texture2D,
	shield:    rl.Texture2D,
}

Assets_Audio :: struct {
	music_battle:    rl.Music,
	music_overworld: rl.Music,
	music_menu:      rl.Music,
}

@(private = "file")
assets_sprites_load :: proc(sprites_dir: string) -> Assets_Sprites {
	return Assets_Sprites {
		player = load_atlas(sprites_dir, "player.json"),
		grass = load_sprite(sprites_dir, "grass.png"),
		main_menu = load_sprite(sprites_dir, "main_menu.png"),
		heart = load_sprite(sprites_dir, "heart.png"),
		shield = load_sprite(sprites_dir, "shield.png"),
	}
}

@(private = "file")
assets_sprites_unload :: proc(sprites: ^Assets_Sprites) {
	atlas.unload(&sprites.player)
	rl.UnloadTexture(sprites.grass)
	rl.UnloadTexture(sprites.main_menu)
	rl.UnloadTexture(sprites.heart)
	rl.UnloadTexture(sprites.shield)
}

@(private = "file")
load_sprite :: proc(sprites_dir: string, name: string) -> rl.Texture2D {
	texture := rl.LoadTexture(fmt.ctprintf("%s/%s", sprites_dir, name))
	rl.SetTextureFilter(texture, .POINT)
	return texture
}

@(private = "file")
load_atlas :: proc(sprites_dir: string, name: string) -> atlas.Atlas {
	path := slashpath.join({sprites_dir, name}, context.temp_allocator)
	atlas, err := atlas.load(path)
	if err != nil {
		panic(fmt.tprintf("Could not load atlas: %v", err))
	}
	rl.SetTextureFilter(atlas.texture, .POINT)
	return atlas
}

@(private = "file")
assets_audio_load :: proc(audio_dir: string) -> Assets_Audio {
	return {
		music_battle = load_music(audio_dir, "music-battle.ogg"),
		music_overworld = load_music(audio_dir, "music-overworld.ogg"),
		music_menu = load_music(audio_dir, "music-menu.ogg"),
	}
}

assets_audio_unload :: proc(audio: ^Assets_Audio) {
	rl.UnloadMusicStream(audio.music_battle)
	rl.UnloadMusicStream(audio.music_overworld)
	rl.UnloadMusicStream(audio.music_menu)
}

@(private = "file")
load_music :: proc(sprites_dir: string, name: string) -> rl.Music {
	path := slashpath.join({sprites_dir, name}, context.temp_allocator)
	cpath := strings.clone_to_cstring(path, context.temp_allocator)
	return rl.LoadMusicStream(cpath)
}
