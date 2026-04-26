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
	tilemap_level_2: tiled.Tilemap,
}

assets_load :: proc(assets_dir: string = "assets") -> ^Assets {
	assets := new(Assets)
	assets.sprites = assets_sprites_load(fmt.tprintf("%s/%s", assets_dir, "sprites"))
	assets.audio = assets_audio_load(slashpath.join({assets_dir, "audio"}, context.temp_allocator))
	assets.tiled_loader = tiled.loader_make()

	tilemap_level_1, _ := tiled.tilemap_load(assets.tiled_loader, "./assets/tilemaps/level-1.tmj")
	assets.tilemap_level_1 = tilemap_level_1
	tilemap_level_2, _ := tiled.tilemap_load(assets.tiled_loader, "./assets/tilemaps/level-2.tmj")
	assets.tilemap_level_2 = tilemap_level_2

	for _, tileset in assets.tiled_loader.tilesets {
		rl.SetTextureFilter(tileset.texture, .POINT)
	}


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
	music_battle:     rl.Music,
	music_overworld:  rl.Music,
	music_menu:       rl.Music,
	fx_action:        rl.Sound,
	fx_button:        rl.Sound,
	fx_damage:        rl.Sound,
	fx_death:         rl.Sound,
	fx_deflect:       rl.Sound,
	fx_extra_shield:  rl.Sound,
	fx_fall:          rl.Sound,
	fx_gauntlet:      rl.Sound,
	fx_gunshot:       rl.Sound,
	fx_melee:         rl.Sound,
	fx_parry:         rl.Sound,
	fx_projectile:    rl.Sound,
	fx_steps:         rl.Sound,
	fx_warning:       rl.Sound,
	jingle_dead:      rl.Music,
	jingle_encounter: rl.Music,
	jingle_win:       rl.Music,
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
		fx_action = load_sound(audio_dir, "fx-action.ogg"),
		fx_button = load_sound(audio_dir, "fx-button.ogg"),
		fx_damage = load_sound(audio_dir, "fx-damage.ogg"),
		fx_death = load_sound(audio_dir, "fx-death.ogg"),
		fx_deflect = load_sound(audio_dir, "fx-deflect.ogg"),
		fx_extra_shield = load_sound(audio_dir, "fx-extra-shield.ogg"),
		fx_fall = load_sound(audio_dir, "fx-fall.ogg"),
		fx_gauntlet = load_sound(audio_dir, "fx-gauntlet.ogg"),
		fx_gunshot = load_sound(audio_dir, "fx-gunshot.ogg"),
		fx_melee = load_sound(audio_dir, "fx-melee.ogg"),
		fx_parry = load_sound(audio_dir, "fx-parry.ogg"),
		fx_projectile = load_sound(audio_dir, "fx-projectile.ogg"),
		fx_steps = load_sound(audio_dir, "fx-steps.ogg"),
		fx_warning = load_sound(audio_dir, "fx-warning.ogg"),
		jingle_dead = load_music(audio_dir, "jingle-dead.ogg"),
		jingle_encounter = load_music(audio_dir, "jingle-encounter.ogg"),
		jingle_win = load_music(audio_dir, "jingle-win.ogg"),
	}
}

assets_audio_unload :: proc(audio: ^Assets_Audio) {
	rl.UnloadMusicStream(audio.music_battle)
	rl.UnloadMusicStream(audio.music_overworld)
	rl.UnloadMusicStream(audio.music_menu)
	rl.UnloadSound(audio.fx_action)
	rl.UnloadSound(audio.fx_button)
	rl.UnloadSound(audio.fx_damage)
	rl.UnloadSound(audio.fx_death)
	rl.UnloadSound(audio.fx_deflect)
	rl.UnloadSound(audio.fx_extra_shield)
	rl.UnloadSound(audio.fx_fall)
	rl.UnloadSound(audio.fx_gauntlet)
	rl.UnloadSound(audio.fx_gunshot)
	rl.UnloadSound(audio.fx_melee)
	rl.UnloadSound(audio.fx_parry)
	rl.UnloadSound(audio.fx_projectile)
	rl.UnloadSound(audio.fx_steps)
	rl.UnloadSound(audio.fx_warning)
	rl.UnloadMusicStream(audio.jingle_dead)
	rl.UnloadMusicStream(audio.jingle_encounter)
	rl.UnloadMusicStream(audio.jingle_win)
}

@(private = "file")
load_music :: proc(audio_dir: string, name: string) -> rl.Music {
	path := slashpath.join({audio_dir, name}, context.temp_allocator)
	cpath := strings.clone_to_cstring(path, context.temp_allocator)
	return rl.LoadMusicStream(cpath)
}

@(private = "file")
load_sound :: proc(audio_dir: string, name: string) -> rl.Sound {
	path := slashpath.join({audio_dir, name}, context.temp_allocator)
	cpath := strings.clone_to_cstring(path, context.temp_allocator)
	return rl.LoadSound(cpath)
}
