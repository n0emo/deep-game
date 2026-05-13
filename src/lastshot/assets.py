from __future__ import annotations
import os
from pathlib import Path
import pyray as rl
from dataclasses import dataclass
from atlas import Atlas
from lastshot.sprite import Sprite, sprite_get
from .animation import Animation, animation_frame_from_atlas
from .direction import Direction
from tiled import Tilemap, Loader


@dataclass
class AssetsSprites:
    player: Atlas
    fight_entity: Atlas
    icons: Atlas
    projectiles: Atlas
    icon_arrow_down: Sprite
    icon_attack_mellee: Sprite
    icon_attack_range: Sprite
    icon_damage: Sprite
    icon_exclamation: Sprite
    icon_exit: Sprite
    icon_heart: Sprite
    icon_parry: Sprite
    icon_retry: Sprite
    icon_settings: Sprite
    icon_shield: Sprite
    icon_start_game: Sprite
    projectile_gear: Sprite
    projectile_brass_bullet: Sprite
    projectile_sun_core: Sprite
    projectile_bearing: Sprite
    projectile_metal_ball: Sprite
    projectile_small_bullet: Sprite
    projectile_spikes: Sprite
    bg_main_menu: rl.Texture
    bg_dead: rl.Texture
    bg_win: rl.Texture
    fight_background: rl.Texture
    player_transitioning: rl.Texture


@dataclass
class AssetsAnimations:
    player_overworld_idle: dict[Direction, Animation]
    player_overworld_moving: dict[Direction, Animation]
    player_fight_idle: Animation
    player_fight_ranged_attack: Animation
    player_fight_melee_attack: Animation
    enemy_melee_idle: Animation
    enemy_melee_melee_attack: Animation
    enemy_ranger_idle: Animation
    enemy_ranger_ranged_attack: Animation
    enemy_gear_idle: Animation
    enemy_gear_melee_attack: Animation
    enemy_turret_idle: Animation
    enemy_turret_ranged_attack: Animation
    enemy_drone_idle: Animation
    enemy_drone_ranged_attack: Animation
    enemy_fanatic_idle: Animation
    enemy_fanatic_melee_attack: Animation
    enemy_fanatic_ranged_attack: Animation
    enemy_lastguardian_idle: Animation
    enemy_lastguardian_melee_attack: Animation
    enemy_lastguardian_ranged_attack: Animation


@dataclass
class AssetsAudio:
    music_battle: rl.Music
    music_overworld: rl.Music
    music_menu: rl.Music
    fx_action: rl.Sound
    fx_button: rl.Sound
    fx_damage: rl.Sound
    fx_death: rl.Sound
    fx_deflect: rl.Sound
    fx_extra_shield: rl.Sound
    fx_fall: rl.Sound
    fx_gauntlet: rl.Sound
    fx_gunshot: rl.Sound
    fx_melee: rl.Sound
    fx_parry: rl.Sound
    fx_projectile: rl.Sound
    fx_steps: rl.Sound
    fx_warning: rl.Sound
    jingle_dead: rl.Music
    jingle_encounter: rl.Music
    jingle_win: rl.Music


@dataclass
class Assets:
    tilemap_loader: Loader
    sprites: AssetsSprites
    animations: AssetsAnimations
    audio: AssetsAudio
    tilemap_level_1: Tilemap
    tilemap_level_2: Tilemap

    @staticmethod
    def load(assets_dir: str = "assets") -> Assets:
        tilemap_loader = Loader()
        sprites = _load_sprites(os.path.join(assets_dir, "sprites"))
        return Assets(
            tilemap_loader=tilemap_loader,
            sprites=sprites,
            animations=_animations_from_sprites(sprites),
            audio=_load_audio(os.path.join(assets_dir, "audio")),
            tilemap_level_1=tilemap_loader.load_tilemap(
                Path("./assets/tilemaps/level-1.tmj")
            ),
            tilemap_level_2=tilemap_loader.load_tilemap(
                Path("./assets/tilemaps/level-2.tmj")
            ),
        )

    def unload(self) -> None:
        _unload_sprites(self.sprites)
        _unload_audio(self.audio)


def _load_sprites(sprites_dir: str) -> AssetsSprites:
    player = _load_atlas(sprites_dir, "player.json")
    fight_entity = _load_atlas(sprites_dir, "fight-entity.json")
    icons = _load_atlas(sprites_dir, "icons.json")
    projectiles = _load_atlas(sprites_dir, "projectiles.json")

    return AssetsSprites(
        player=player,
        fight_entity=fight_entity,
        icons=icons,
        projectiles=projectiles,
        bg_main_menu=_load_texture(sprites_dir, "background-main-menu.png"),
        bg_dead=_load_texture(sprites_dir, "background-dead.png"),
        bg_win=_load_texture(sprites_dir, "background-win.png"),
        fight_background=_load_texture(sprites_dir, "fight-background.png"),
        player_transitioning=_load_texture(sprites_dir, "player-main-menu.png"),
        icon_arrow_down=sprite_get(icons, "icon-arrow-down"),
        icon_attack_mellee=sprite_get(icons, "icon-attack-mellee"),
        icon_attack_range=sprite_get(icons, "icon-attack-range"),
        icon_damage=sprite_get(icons, "icon-damage"),
        icon_exclamation=sprite_get(icons, "icon-exclamation"),
        icon_exit=sprite_get(icons, "icon-exit"),
        icon_heart=sprite_get(icons, "icon-heart"),
        icon_parry=sprite_get(icons, "icon-parry"),
        icon_retry=sprite_get(icons, "icon-retry"),
        icon_settings=sprite_get(icons, "icon-settings"),
        icon_shield=sprite_get(icons, "icon-shield"),
        icon_start_game=sprite_get(icons, "icon-start-game"),
        projectile_gear=sprite_get(projectiles, "projectile-gear"),
        projectile_brass_bullet=sprite_get(projectiles, "projectile-brass-bullet"),
        projectile_sun_core=sprite_get(projectiles, "projectile-sun-core"),
        projectile_bearing=sprite_get(projectiles, "projectile-bearing"),
        projectile_metal_ball=sprite_get(projectiles, "projectile-metal-ball"),
        projectile_small_bullet=sprite_get(projectiles, "projectile-small-bullet"),
        projectile_spikes=sprite_get(projectiles, "projectile-spikes"),
    )


def _unload_sprites(sprites: AssetsSprites) -> None:
    sprites.player.unload()
    sprites.fight_entity.unload()
    sprites.icons.unload()
    sprites.projectiles.unload()
    rl.unload_texture(sprites.bg_main_menu)
    rl.unload_texture(sprites.bg_dead)
    rl.unload_texture(sprites.bg_win)
    rl.unload_texture(sprites.fight_background)
    rl.unload_texture(sprites.player_transitioning)


def _animations_from_sprites(sprites: AssetsSprites) -> AssetsAnimations:
    p = sprites.player
    fe = sprites.fight_entity

    def player_anim(prefix: str) -> Animation:
        return Animation(
            texture=p.texture,
            frames=[animation_frame_from_atlas(p, f"{prefix}-{i}") for i in range(4)],
        )

    def fight_anim(prefix: str, count: int = 2) -> Animation:
        return Animation(
            texture=fe.texture,
            frames=[
                animation_frame_from_atlas(fe, f"{prefix}-{i}") for i in range(count)
            ],
        )

    return AssetsAnimations(
        player_overworld_idle={
            Direction.UP: player_anim("player-idle-back"),
            Direction.DOWN: player_anim("player-idle-front"),
            Direction.LEFT: player_anim("player-idle-left"),
            Direction.RIGHT: player_anim("player-idle-right"),
        },
        player_overworld_moving={
            Direction.UP: player_anim("player-move-back"),
            Direction.DOWN: player_anim("player-move-front"),
            Direction.LEFT: player_anim("player-move-left"),
            Direction.RIGHT: player_anim("player-move-right"),
        },
        player_fight_idle=fight_anim("player-fight-idle"),
        player_fight_ranged_attack=fight_anim("player-fight-range-attack"),
        player_fight_melee_attack=fight_anim("player-fight-melee-attack"),
        enemy_melee_idle=fight_anim("enemy-fight-melee-idle"),
        enemy_melee_melee_attack=fight_anim("enemy-fight-melee-attack"),
        enemy_ranger_idle=fight_anim("enemy-fight-ranger-idle"),
        enemy_ranger_ranged_attack=fight_anim("enemy-fight-ranger-attack"),
        enemy_gear_idle=fight_anim("enemy-fight-gear-idle"),
        enemy_gear_melee_attack=fight_anim("enemy-fight-gear-attack"),
        enemy_turret_idle=fight_anim("enemy-fight-turret-idle"),
        enemy_turret_ranged_attack=fight_anim("enemy-fight-turret-attack"),
        enemy_drone_idle=fight_anim("enemy-fight-drone-idle"),
        enemy_drone_ranged_attack=fight_anim("enemy-fight-drone-attack"),
        enemy_fanatic_idle=fight_anim("enemy-fight-fanatic-idle"),
        enemy_fanatic_melee_attack=fight_anim("enemy-fight-fanatic-melee-attack"),
        enemy_fanatic_ranged_attack=fight_anim("enemy-fight-fanatic-range-attack"),
        enemy_lastguardian_idle=fight_anim("enemy-fight-last-guardian-idle"),
        enemy_lastguardian_melee_attack=fight_anim(
            "enemy-fight-last-guardian-melee-attack"
        ),
        enemy_lastguardian_ranged_attack=fight_anim(
            "enemy-fight-last-guardian-range-attack"
        ),
    )


def _load_audio(audio_dir: str) -> AssetsAudio:
    return AssetsAudio(
        music_battle=_load_music(audio_dir, "music-battle.ogg"),
        music_overworld=_load_music(audio_dir, "music-overworld.ogg"),
        music_menu=_load_music(audio_dir, "music-menu.ogg"),
        fx_action=_load_sound(audio_dir, "fx-action.ogg"),
        fx_button=_load_sound(audio_dir, "fx-button.ogg"),
        fx_damage=_load_sound(audio_dir, "fx-damage.ogg"),
        fx_death=_load_sound(audio_dir, "fx-death.ogg"),
        fx_deflect=_load_sound(audio_dir, "fx-deflect.ogg"),
        fx_extra_shield=_load_sound(audio_dir, "fx-extra-shield.ogg"),
        fx_fall=_load_sound(audio_dir, "fx-fall.ogg"),
        fx_gauntlet=_load_sound(audio_dir, "fx-gauntlet.ogg"),
        fx_gunshot=_load_sound(audio_dir, "fx-gunshot.ogg"),
        fx_melee=_load_sound(audio_dir, "fx-melee.ogg"),
        fx_parry=_load_sound(audio_dir, "fx-parry.ogg"),
        fx_projectile=_load_sound(audio_dir, "fx-projectile.ogg"),
        fx_steps=_load_sound(audio_dir, "fx-steps.ogg"),
        fx_warning=_load_sound(audio_dir, "fx-warning.ogg"),
        jingle_dead=_load_music(audio_dir, "jingle-dead.ogg"),
        jingle_encounter=_load_music(audio_dir, "jingle-encounter.ogg"),
        jingle_win=_load_music(audio_dir, "jingle-win.ogg"),
    )


def _unload_audio(audio: AssetsAudio) -> None:
    rl.unload_music_stream(audio.music_battle)
    rl.unload_music_stream(audio.music_overworld)
    rl.unload_music_stream(audio.music_menu)
    rl.unload_sound(audio.fx_action)
    rl.unload_sound(audio.fx_button)
    rl.unload_sound(audio.fx_damage)
    rl.unload_sound(audio.fx_death)
    rl.unload_sound(audio.fx_deflect)
    rl.unload_sound(audio.fx_extra_shield)
    rl.unload_sound(audio.fx_fall)
    rl.unload_sound(audio.fx_gauntlet)
    rl.unload_sound(audio.fx_gunshot)
    rl.unload_sound(audio.fx_melee)
    rl.unload_sound(audio.fx_parry)
    rl.unload_sound(audio.fx_projectile)
    rl.unload_sound(audio.fx_steps)
    rl.unload_sound(audio.fx_warning)
    rl.unload_music_stream(audio.jingle_dead)
    rl.unload_music_stream(audio.jingle_encounter)
    rl.unload_music_stream(audio.jingle_win)


def _load_texture(sprites_dir: str, name: str) -> rl.Texture:
    texture = rl.load_texture(os.path.join(sprites_dir, name))
    rl.set_texture_filter(texture, rl.TextureFilter.TEXTURE_FILTER_POINT)
    return texture


def _load_atlas(sprites_dir: str, name: str) -> Atlas:
    atlas = Atlas.load(os.path.join(sprites_dir, name))
    rl.set_texture_filter(atlas.texture, rl.TextureFilter.TEXTURE_FILTER_POINT)
    return atlas


def _load_music(audio_dir: str, name: str) -> rl.Music:
    return rl.load_music_stream(os.path.join(audio_dir, name))


def _load_sound(audio_dir: str, name: str) -> rl.Sound:
    return rl.load_sound(os.path.join(audio_dir, name))
