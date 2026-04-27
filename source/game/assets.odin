package game

import "../atlas"
import "../tiled"
import "core:fmt"
import "core:path/slashpath"
import "core:strings"
import rl "vendor:raylib"

Assets :: struct {
	sprites:         Assets_Sprites,
	animations:      Assets_Animations,
	audio:           Assets_Audio,
	tiled_loader:    ^tiled.Loader,
	tilemap_level_1: tiled.Tilemap,
	tilemap_level_2: tiled.Tilemap,
}

assets_load :: proc(assets_dir: string = "assets") -> ^Assets {
	ok: bool

	assets := new(Assets)
	if assets.sprites, ok = assets_sprites_load(fmt.tprintf("%s/%s", assets_dir, "sprites")); !ok {
		panic("Could not load sprites")
	}
	assets.animations, _ = assets_animations_from_sprites(assets.sprites)
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
	player:                  atlas.Atlas,
	fight_entity:            atlas.Atlas,
	icons:                   atlas.Atlas,
	projectiles:             atlas.Atlas,
	icon_arrow_down:         Sprite,
	icon_attack_mellee:      Sprite,
	icon_attack_range:       Sprite,
	icon_damage:             Sprite,
	icon_exclamation:        Sprite,
	icon_exit:               Sprite,
	icon_heart:              Sprite,
	icon_parry:              Sprite,
	icon_retry:              Sprite,
	icon_settings:           Sprite,
	icon_shield:             Sprite,
	icon_start_game:         Sprite,
	projectile_gear:         Sprite,
	projectile_brass_bullet: Sprite,
	projectile_sun_core:     Sprite,
	projectile_bearing:      Sprite,
	projectile_metal_ball:   Sprite,
	projectile_small_bullet: Sprite,
	projectile_spikes:       Sprite,
	bg_main_menu:            rl.Texture2D,
	bg_dead:                 rl.Texture2D,
	bg_win:                  rl.Texture2D,
	fight_background:        rl.Texture2D,
	player_transitioning:    rl.Texture2D,
}

Assets_Animations :: struct {
	player_overworld_idle:            [Direction]Animation,
	player_overworld_moving:          [Direction]Animation,
	player_fight_idle:                Animation,
	player_fight_ranged_attack:       Animation,
	player_fight_melee_attack:        Animation,
	enemy_melee_idle:                 Animation,
	enemy_melee_melee_attack:         Animation,
	enemy_ranger_idle:                Animation,
	enemy_ranger_ranged_attack:       Animation,
	enemy_gear_idle:                  Animation,
	enemy_gear_melee_attack:          Animation,
	enemy_turret_idle:                Animation,
	enemy_turret_ranged_attack:       Animation,
	enemy_drone_idle:                 Animation,
	enemy_drone_ranged_attack:        Animation,
	enemy_fanatic_idle:               Animation,
	enemy_fanatic_melee_attack:       Animation,
	enemy_fanatic_ranged_attack:      Animation,
	enemy_lastguardian_idle:          Animation,
	enemy_lastguardian_melee_attack:  Animation,
	enemy_lastguardian_ranged_attack: Animation,
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
assets_sprites_load :: proc(sprites_dir: string) -> (sprites: Assets_Sprites, ok: bool) {
	player := load_atlas(sprites_dir, "player.json")
	fight_entity := load_atlas(sprites_dir, "fight-entity.json")
	icons := load_atlas(sprites_dir, "icons.json")
	projectiles := load_atlas(sprites_dir, "projectiles.json")

	sprites = Assets_Sprites {
		player                  = player,
		fight_entity            = fight_entity,
		icons                   = icons,
		projectiles             = projectiles,
		bg_main_menu            = load_sprite(sprites_dir, "background-main-menu.png"),
		bg_dead                 = load_sprite(sprites_dir, "background-dead.png"),
		bg_win                  = load_sprite(sprites_dir, "background-win.png"),
		fight_background        = load_sprite(sprites_dir, "fight-background.png"),
		player_transitioning    = load_sprite(sprites_dir, "player-main-menu.png"),
		projectile_gear         = sprite_get(&projectiles, "projectile-gear") or_return,
		projectile_brass_bullet = sprite_get(&projectiles, "projectile-brass-bullet") or_return,
		projectile_sun_core     = sprite_get(&projectiles, "projectile-sun-core") or_return,
		projectile_bearing      = sprite_get(&projectiles, "projectile-bearing") or_return,
		projectile_metal_ball   = sprite_get(&projectiles, "projectile-metal-ball") or_return,
		projectile_small_bullet = sprite_get(&projectiles, "projectile-small-bullet") or_return,
		projectile_spikes       = sprite_get(&projectiles, "projectile-spikes") or_return,
	}
	return sprites, true
}

@(private = "file")
assets_sprites_unload :: proc(sprites: ^Assets_Sprites) {
	atlas.unload(&sprites.player)
	atlas.unload(&sprites.fight_entity)
	rl.UnloadTexture(sprites.bg_main_menu)
	rl.UnloadTexture(sprites.bg_dead)
	rl.UnloadTexture(sprites.bg_win)
	rl.UnloadTexture(sprites.fight_background)
	rl.UnloadTexture(sprites.player_transitioning)
}

@(private = "file")
assets_animations_from_sprites :: proc(
	sprites: Assets_Sprites,
) -> (
	animations: Assets_Animations,
	ok: bool,
) {
	animations.player_overworld_idle = [Direction]Animation {
		.Up    = animation_make(
			sprites.player.texture,
			{
				animation_frame_from_atlas(sprites.player, "player-idle-back-0"),
				animation_frame_from_atlas(sprites.player, "player-idle-back-1"),
				animation_frame_from_atlas(sprites.player, "player-idle-back-2"),
				animation_frame_from_atlas(sprites.player, "player-idle-back-3"),
			},
		),
		.Down  = animation_make(
			sprites.player.texture,
			{
				animation_frame_from_atlas(sprites.player, "player-idle-front-0"),
				animation_frame_from_atlas(sprites.player, "player-idle-front-1"),
				animation_frame_from_atlas(sprites.player, "player-idle-front-2"),
				animation_frame_from_atlas(sprites.player, "player-idle-front-3"),
			},
		),
		.Left  = animation_make(
			sprites.player.texture,
			{
				animation_frame_from_atlas(sprites.player, "player-idle-left-0"),
				animation_frame_from_atlas(sprites.player, "player-idle-left-1"),
				animation_frame_from_atlas(sprites.player, "player-idle-left-2"),
				animation_frame_from_atlas(sprites.player, "player-idle-left-3"),
			},
		),
		.Right = animation_make(
			sprites.player.texture,
			{
				animation_frame_from_atlas(sprites.player, "player-idle-right-0"),
				animation_frame_from_atlas(sprites.player, "player-idle-right-1"),
				animation_frame_from_atlas(sprites.player, "player-idle-right-2"),
				animation_frame_from_atlas(sprites.player, "player-idle-right-3"),
			},
		),
	}

	animations.player_overworld_moving = [Direction]Animation {
		.Up    = animation_make(
			sprites.player.texture,
			{
				animation_frame_from_atlas(sprites.player, "player-move-back-0"),
				animation_frame_from_atlas(sprites.player, "player-move-back-1"),
				animation_frame_from_atlas(sprites.player, "player-move-back-2"),
				animation_frame_from_atlas(sprites.player, "player-move-back-3"),
			},
		),
		.Down  = animation_make(
			sprites.player.texture,
			{
				animation_frame_from_atlas(sprites.player, "player-move-front-0"),
				animation_frame_from_atlas(sprites.player, "player-move-front-1"),
				animation_frame_from_atlas(sprites.player, "player-move-front-2"),
				animation_frame_from_atlas(sprites.player, "player-move-front-3"),
			},
		),
		.Left  = animation_make(
			sprites.player.texture,
			{
				animation_frame_from_atlas(sprites.player, "player-move-left-0"),
				animation_frame_from_atlas(sprites.player, "player-move-left-1"),
				animation_frame_from_atlas(sprites.player, "player-move-left-2"),
				animation_frame_from_atlas(sprites.player, "player-move-left-3"),
			},
		),
		.Right = animation_make(
			sprites.player.texture,
			{
				animation_frame_from_atlas(sprites.player, "player-move-right-0"),
				animation_frame_from_atlas(sprites.player, "player-move-right-1"),
				animation_frame_from_atlas(sprites.player, "player-move-right-2"),
				animation_frame_from_atlas(sprites.player, "player-move-right-3"),
			},
		),
	}

	animations.player_fight_idle = animation_make(
		sprites.fight_entity.texture,
		{
			animation_frame_from_atlas(sprites.fight_entity, "player-fight-idle-0"),
			animation_frame_from_atlas(sprites.fight_entity, "player-fight-idle-1"),
		},
	)

	animations.player_fight_ranged_attack = animation_make(
		sprites.fight_entity.texture,
		{
			animation_frame_from_atlas(sprites.fight_entity, "player-fight-range-attack-0"),
			animation_frame_from_atlas(sprites.fight_entity, "player-fight-range-attack-1"),
		},
	)

	animations.player_fight_melee_attack = animation_make(
		sprites.fight_entity.texture,
		{
			animation_frame_from_atlas(sprites.fight_entity, "player-fight-melee-attack-0"),
			animation_frame_from_atlas(sprites.fight_entity, "player-fight-melee-attack-1"),
		},
	)

	animations.enemy_melee_idle = animation_make(
		sprites.fight_entity.texture,
		{
			animation_frame_from_atlas(sprites.fight_entity, "enemy-fight-melee-idle-0"),
			animation_frame_from_atlas(sprites.fight_entity, "enemy-fight-melee-idle-1"),
		},
	)

	animations.enemy_melee_melee_attack = animation_make(
		sprites.fight_entity.texture,
		{
			animation_frame_from_atlas(sprites.fight_entity, "enemy-fight-melee-attack-0"),
			animation_frame_from_atlas(sprites.fight_entity, "enemy-fight-melee-attack-1"),
		},
	)

	animations.enemy_ranger_idle = animation_make(
		sprites.fight_entity.texture,
		{
			animation_frame_from_atlas(sprites.fight_entity, "enemy-fight-ranger-idle-0"),
			animation_frame_from_atlas(sprites.fight_entity, "enemy-fight-ranger-idle-1"),
		},
	)

	animations.enemy_ranger_ranged_attack = animation_make(
		sprites.fight_entity.texture,
		{
			animation_frame_from_atlas(sprites.fight_entity, "enemy-fight-ranger-attack-0"),
			animation_frame_from_atlas(sprites.fight_entity, "enemy-fight-ranger-attack-1"),
		},
	)

	animations.enemy_gear_idle = animation_make(
		sprites.fight_entity.texture,
		{
			animation_frame_from_atlas(sprites.fight_entity, "enemy-fight-gear-idle-0"),
			animation_frame_from_atlas(sprites.fight_entity, "enemy-fight-gear-idle-1"),
		},
	)

	animations.enemy_gear_melee_attack = animation_make(
		sprites.fight_entity.texture,
		{
			animation_frame_from_atlas(sprites.fight_entity, "enemy-fight-gear-attack-0"),
			animation_frame_from_atlas(sprites.fight_entity, "enemy-fight-gear-attack-1"),
		},
	)

	animations.enemy_turret_idle = animation_make(
		sprites.fight_entity.texture,
		{
			animation_frame_from_atlas(sprites.fight_entity, "enemy-fight-turret-idle-0"),
			animation_frame_from_atlas(sprites.fight_entity, "enemy-fight-turret-idle-1"),
		},
	)

	animations.enemy_turret_ranged_attack = animation_make(
		sprites.fight_entity.texture,
		{
			animation_frame_from_atlas(sprites.fight_entity, "enemy-fight-turret-attack-0"),
			animation_frame_from_atlas(sprites.fight_entity, "enemy-fight-turret-attack-1"),
		},
	)

	animations.enemy_drone_idle = animation_make(
		sprites.fight_entity.texture,
		{
			animation_frame_from_atlas(sprites.fight_entity, "enemy-fight-drone-idle-0"),
			animation_frame_from_atlas(sprites.fight_entity, "enemy-fight-drone-idle-1"),
		},
	)

	animations.enemy_drone_ranged_attack = animation_make(
		sprites.fight_entity.texture,
		{
			animation_frame_from_atlas(sprites.fight_entity, "enemy-fight-drone-attack-0"),
			animation_frame_from_atlas(sprites.fight_entity, "enemy-fight-drone-attack-1"),
		},
	)

	animations.enemy_fanatic_idle = animation_make(
		sprites.fight_entity.texture,
		{
			animation_frame_from_atlas(sprites.fight_entity, "enemy-fight-fanatic-idle-0"),
			animation_frame_from_atlas(sprites.fight_entity, "enemy-fight-fanatic-idle-1"),
		},
	)

	animations.enemy_fanatic_ranged_attack = animation_make(
		sprites.fight_entity.texture,
		{
			animation_frame_from_atlas(sprites.fight_entity, "enemy-fight-fanatic-melee-attack-0"),
			animation_frame_from_atlas(sprites.fight_entity, "enemy-fight-fanatic-melee-attack-1"),
		},
	)

	animations.enemy_fanatic_melee_attack = animation_make(
		sprites.fight_entity.texture,
		{
			animation_frame_from_atlas(sprites.fight_entity, "enemy-fight-fanatic-range-attack-0"),
			animation_frame_from_atlas(sprites.fight_entity, "enemy-fight-fanatic-range-attack-1"),
		},
	)

	animations.enemy_lastguardian_idle = animation_make(
		sprites.fight_entity.texture,
		{
			animation_frame_from_atlas(sprites.fight_entity, "enemy-fight-last-guardian-idle-0"),
			animation_frame_from_atlas(sprites.fight_entity, "enemy-fight-last-guardian-idle-1"),
		},
	)

	animations.enemy_lastguardian_ranged_attack = animation_make(
		sprites.fight_entity.texture,
		{
			animation_frame_from_atlas(
				sprites.fight_entity,
				"enemy-fight-last-guardian-melee-attack-0",
			),
			animation_frame_from_atlas(
				sprites.fight_entity,
				"enemy-fight-last-guardian-melee-attack-1",
			),
		},
	)

	animations.enemy_lastguardian_melee_attack = animation_make(
		sprites.fight_entity.texture,
		{
			animation_frame_from_atlas(
				sprites.fight_entity,
				"enemy-fight-last-guardian-range-attack-0",
			),
			animation_frame_from_atlas(
				sprites.fight_entity,
				"enemy-fight-last-guardian-range-attack-1",
			),
		},
	)

	return
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
