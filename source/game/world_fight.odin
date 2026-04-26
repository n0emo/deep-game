package game

import atlas "../atlas"
import "core:fmt"
import "core:math/linalg"
import "core:math/rand"
import rl "vendor:raylib"

@(private = "file")
UI_HEIGHT :: 250

@(private = "file")
FIGHT_LINE :: UI_HEIGHT + 150

@(private = "file")
BUTTON_SIZE :: rl.Vector2{300, 50}

@(private = "file")
PADDING :: 20

@(private = "file")
BUTTON_GAP :: 10

@(private = "file")
GUYS_PADDING :: 100

@(private = "file")
GUYS_LIMIT :: 100

@(private = "file")
PROJECTILE_SPEED :: 2

@(private = "file")
PROJECTILE_LIMIT :: 10

@(private = "file")
ENEMY_READY_TIME :: 1.5

@(private = "file")
ENEMY_WARN_TIME :: 1

World_Fight :: struct {
	player:                  World_Fight_Player,
	enemy:                   World_Fight_Enemy,
	state:                   Fight_State,
	assets:                  ^Assets,
	projectile_interpolator: f32,
}

Fight_State :: enum {
	Player_Turn,
	Player_Attacking_Melee,
	Player_Attacking_Range,
	Enemy_Turn,
	Enemy_Attacking_Melee,
	Enemy_Attacking_Range,
}

World_Fight_Player :: struct {
	pos_interpolator:       f32,
	hp:                     int,
	shield:                 int,
	melee_damage:           int,
	range_damage:           int,
	animation_current:      ^Animation,
	animation_idle:         Animation,
	animation_attack_melee: Animation,
	animation_attack_range: Animation,
}

World_Fight_Enemy :: struct {
	pos_interpolator:         f32,
	hp:                       int,
	max_hp:                   int,
	name:                     string,
	melee_attack_probability: f32,
	melee_damage:             int,
	range_damage:             int,
	melee_damage_reduction:   f32,
	range_damage_reduction:   f32,
	ready_time:               f32,
	animation_current:        ^Animation,
	animation_idle:           Animation,
	animation_attack_melee:   Animation,
	animation_attack_range:   Animation,
	pos:                      rl.Vector2,
}

Turn :: enum {
	Player,
	Enemy,
}

world_fight_make :: proc(assets: ^Assets, enemy_hp: int, enemy_name: string) -> World_Fight {
	player := player_make(&assets.sprites.player)
	enemy := enemy_make(
		&assets.sprites.player,
		enemy_hp,
		enemy_name,
		rl.Vector2{cast(f32)(rl.GetScreenWidth() / 8), 0},
	)
	return {state = .Player_Turn, enemy = enemy, player = player, assets = assets}
}

// TODO: move to something like enemy.odin
// TODO: melee/ranged attack probability
enemy_make :: proc(
	atlas: ^atlas.Atlas,
	enemy_hp: int,
	enemy_name: string,
	pos: rl.Vector2,
) -> World_Fight_Enemy {
	animation_idle := animation_make(
		atlas.texture,
		{
			animation_frame_from_atlas(atlas, "player-idle-right-0"),
			animation_frame_from_atlas(atlas, "player-idle-right-1"),
			animation_frame_from_atlas(atlas, "player-idle-right-2"),
			animation_frame_from_atlas(atlas, "player-idle-right-3"),
		},
	)
	animation_attack_melee := animation_make(
		atlas.texture,
		{
			animation_frame_from_atlas(atlas, "player-idle-left-0"),
			animation_frame_from_atlas(atlas, "player-idle-left-1"),
			animation_frame_from_atlas(atlas, "player-idle-left-2"),
			animation_frame_from_atlas(atlas, "player-idle-left-3"),
		},
		loop = false,
	)
	animation_attack_range := animation_make(
		atlas.texture,
		{
			animation_frame_from_atlas(atlas, "player-idle-down-0"),
			animation_frame_from_atlas(atlas, "player-idle-down-1"),
			animation_frame_from_atlas(atlas, "player-idle-down-2"),
			animation_frame_from_atlas(atlas, "player-idle-down-3"),
		},
		loop = false,
	)
	return World_Fight_Enemy {
		hp = enemy_hp,
		max_hp = enemy_hp,
		name = enemy_name,
		melee_attack_probability = 0.5,
		melee_damage = 1,
		range_damage = 1,
		melee_damage_reduction = 0.2,
		range_damage_reduction = 0.1,
		animation_current = nil,
		animation_attack_melee = animation_attack_melee,
		animation_attack_range = animation_attack_range,
		animation_idle = animation_idle,
		pos = pos,
	}
}

@(private = "file")
enemy_draw :: proc(enemy: ^World_Fight_Enemy) {
	x_end: f32 = GUYS_PADDING + GUYS_LIMIT
	x_start: f32 = f32(rl.GetScreenWidth()) - GUYS_PADDING

	if enemy.animation_current != nil {
		animation_draw(
			enemy.animation_current,
			{
				ease_in_out_back(x_start, x_end, enemy.pos_interpolator),
				f32(rl.GetScreenHeight()) - FIGHT_LINE,
			},
			centered = true,
			scale = 6,
		)
	}
}

enemy_update :: proc(enemy: ^World_Fight_Enemy, queue: ^Event_Queue) {
	if enemy.animation_current == nil {
		enemy.animation_current = &enemy.animation_idle
	}
	if enemy.animation_current != &enemy.animation_idle &&
	   enemy.animation_current.index >= len(enemy.animation_current.frames) - 1 {
		enemy.animation_current = &enemy.animation_idle
	}
	animation_update(enemy.animation_current)
}

player_make :: proc(atlas: ^atlas.Atlas) -> World_Fight_Player {
	animation_idle := animation_make(
		atlas.texture,
		{
			animation_frame_from_atlas(atlas, "player-idle-right-0"),
			animation_frame_from_atlas(atlas, "player-idle-right-1"),
			animation_frame_from_atlas(atlas, "player-idle-right-2"),
			animation_frame_from_atlas(atlas, "player-idle-right-3"),
		},
	)
	animation_attack_melee := animation_make(
		atlas.texture,
		{
			animation_frame_from_atlas(atlas, "player-idle-left-0"),
			animation_frame_from_atlas(atlas, "player-idle-left-1"),
			animation_frame_from_atlas(atlas, "player-idle-left-2"),
			animation_frame_from_atlas(atlas, "player-idle-left-3"),
		},
		loop = true,
	)
	animation_attack_range := animation_make(
		atlas.texture,
		{
			animation_frame_from_atlas(atlas, "player-idle-down-0"),
			animation_frame_from_atlas(atlas, "player-idle-down-1"),
			animation_frame_from_atlas(atlas, "player-idle-down-2"),
			animation_frame_from_atlas(atlas, "player-idle-down-3"),
		},
		loop = false,
	)

	player := World_Fight_Player {
		hp                     = 1000,
		shield                 = 3,
		melee_damage           = 2,
		range_damage           = 1,
		animation_current      = nil,
		animation_idle         = animation_idle,
		animation_attack_melee = animation_attack_melee,
		animation_attack_range = animation_attack_range,
	}
	return player
}

player_draw :: proc(player: ^World_Fight_Player) {
	x_start: f32 = GUYS_PADDING
	x_end: f32 = f32(rl.GetScreenWidth()) - GUYS_PADDING - GUYS_LIMIT

	if player.animation_current != nil {
		animation_draw(
			player.animation_current,
			{
				ease_in_out_back(x_start, x_end, player.pos_interpolator),
				f32(rl.GetScreenHeight()) - FIGHT_LINE,
			},
			centered = true,
			scale = 6,
		)
	}
}

player_update :: proc(player: ^World_Fight_Player, queue: ^Event_Queue) {
	if player.animation_current == nil {
		player.animation_current = &player.animation_idle
	}
	if player.animation_current != &player.animation_idle &&
	   player.animation_current.index >= len(player.animation_current.frames) - 1 {
		player.animation_current = &player.animation_idle
	}

	animation_update(player.animation_current)
}

world_fight_update :: proc(f: ^World_Fight, queue: ^Event_Queue) {
	player_update(&f.player, queue)
	enemy_update(&f.enemy, queue)
	if f.enemy.hp <= 0 {
		event_dispatch(queue, Event_Fight_Win{})
	}
	if f.player.hp <= 0 {
		event_dispatch(queue, Event_Lose{})
	}

	switch f.state {
	case .Player_Turn:
	case .Player_Attacking_Melee:
		f.player.pos_interpolator += rl.GetFrameTime()
		if f.player.pos_interpolator > 1 {
			f.player.pos_interpolator = 0
			event_dispatch(queue, Event_Fight_Enemy_Turn{})
		}
	case .Player_Attacking_Range:
		f.projectile_interpolator += rl.GetFrameTime() * PROJECTILE_SPEED
		if f.projectile_interpolator > 1 {
			f.projectile_interpolator = 0
			event_dispatch(queue, Event_Fight_Enemy_Turn{})
		}
	case .Enemy_Turn:
		f.enemy.ready_time -= rl.GetFrameTime()
		if f.enemy.ready_time < ENEMY_WARN_TIME {
			// TODO: do warn
		}
		if f.enemy.ready_time < 0 {
			if rand.float32() < f.enemy.melee_attack_probability {
				event_dispatch(queue, Event_Fight_Enemy_Attack_Melee{})
			} else {
				event_dispatch(queue, Event_Fight_Enemy_Attack_Ranged{})
			}
		}
	case .Enemy_Attacking_Melee:
		f.enemy.pos_interpolator += rl.GetFrameTime()
		if f.enemy.pos_interpolator > 1 {
			f.enemy.pos_interpolator = 0
			event_dispatch(queue, Event_Fight_Player_Turn{})
		}
	case .Enemy_Attacking_Range:
		f.projectile_interpolator += rl.GetFrameTime() * PROJECTILE_SPEED
		if f.projectile_interpolator > 1 {
			f.projectile_interpolator = 0
			event_dispatch(queue, Event_Fight_Player_Turn{})
		}
	}
}

world_fight_draw :: proc(f: ^World_Fight) {
	draw_background(f.assets.sprites.fight_background)
	player_draw(&f.player)
	enemy_draw(&f.enemy)
}

world_fight_ui :: proc(f: ^World_Fight, queue: ^Event_Queue) {
	fight_panel_ui(f, queue)
}

fight_panel_ui :: proc(f: ^World_Fight, queue: ^Event_Queue) {
	f.enemy.hp = 500
	// draw_ui_box()
	draw_enemy_hp(f)
	draw_player_hp(f)

	switch f.state {
	case .Player_Turn:
		ui_player_turn(f, queue)
	case .Player_Attacking_Melee:
	case .Player_Attacking_Range:
		x_start: f32 = GUYS_PADDING + PROJECTILE_LIMIT
		x_end: f32 = f32(rl.GetScreenWidth()) - GUYS_PADDING - PROJECTILE_LIMIT
		rl.DrawCircle(
			cast(i32)linalg.lerp(x_start, x_end, f.projectile_interpolator),
			rl.GetScreenHeight() - FIGHT_LINE,
			15,
			rl.RED,
		)
	case .Enemy_Turn:
		if f.enemy.ready_time < ENEMY_WARN_TIME {
			ui_player_defending(f, queue)
		}
	case .Enemy_Attacking_Melee:
		ui_player_defending(f, queue)
	case .Enemy_Attacking_Range:
		x_end: f32 = GUYS_PADDING + PROJECTILE_LIMIT
		x_start: f32 = f32(rl.GetScreenWidth()) - GUYS_PADDING - PROJECTILE_LIMIT
		rl.DrawCircle(
			cast(i32)linalg.lerp(x_start, x_end, f.projectile_interpolator),
			rl.GetScreenHeight() - FIGHT_LINE,
			15,
			rl.RED,
		)

		ui_player_defending(f, queue)
	}

	when ENABLE_DEBUG {
		draw_fight_line()

		if rl.GuiButton(
			{
				x = f32(rl.GetScreenWidth()) - BUTTON_SIZE.x - PADDING,
				y = f32(rl.GetScreenHeight()) - BUTTON_SIZE.y - PADDING,
				width = BUTTON_SIZE.x,
				height = BUTTON_SIZE.y,
			},
			"Press to win",
		) {
			event_dispatch(queue, Event_Fight_Win{})
		}
	}
}

world_fight_handle_event :: proc(f: ^World_Fight, event: Event) {
	#partial switch e in event {
	case Event_Fight_Player_Attack_Melee:
		f.player.animation_current = &f.player.animation_attack_melee
		animation_reset(&f.player.animation_attack_melee)
		f.state = .Player_Attacking_Melee
	case Event_Fight_Player_Attack_Range:
		f.player.animation_current = &f.player.animation_attack_range
		animation_reset(&f.player.animation_attack_range)
		f.state = .Player_Attacking_Range
	case Event_Fight_Enemy_Turn:
		f.state = .Enemy_Turn
		f.enemy.ready_time = ENEMY_READY_TIME
	case Event_Fight_Enemy_Attack_Melee:
		f.state = .Enemy_Attacking_Melee
		f.enemy.pos_interpolator = 0
	case Event_Fight_Enemy_Attack_Ranged:
		f.state = .Enemy_Attacking_Range
		f.enemy.pos_interpolator = 0
	case Event_Fight_Player_Turn:
		f.state = .Player_Turn
	}

}

@(private = "file")
ui_player_turn :: proc(f: ^World_Fight, queue: ^Event_Queue) {
	if rl.GuiButton(
		{
			x = PADDING,
			y = f32(rl.GetScreenHeight()) - BUTTON_SIZE.y - PADDING,
			width = BUTTON_SIZE.x,
			height = BUTTON_SIZE.y,
		},
		"Attack Melee",
	) {
		event_dispatch(queue, Event_Fight_Player_Attack_Melee{damage = f.player.melee_damage})
	}

	if rl.GuiButton(
		{
			x = PADDING,
			y = f32(rl.GetScreenHeight()) - BUTTON_SIZE.y * 2 - BUTTON_GAP - PADDING,
			width = BUTTON_SIZE.x,
			height = BUTTON_SIZE.y,
		},
		"Attack Ranged",
	) {
		event_dispatch(queue, Event_Fight_Player_Attack_Range{damage = f.player.range_damage})
	}
}

ui_player_defending :: proc(f: ^World_Fight, queue: ^Event_Queue) {
	if rl.GuiButton(
		{
			x = PADDING,
			y = f32(rl.GetScreenHeight()) - BUTTON_SIZE.y - PADDING,
			width = BUTTON_SIZE.x,
			height = BUTTON_SIZE.y,
		},
		"Deflect",
	) {
		event_dispatch(queue, Event_Fight_Player_Deflect{})
	}

	if rl.GuiButton(
		{
			x = PADDING,
			y = f32(rl.GetScreenHeight()) - BUTTON_SIZE.y * 2 - BUTTON_GAP - PADDING,
			width = BUTTON_SIZE.x,
			height = BUTTON_SIZE.y,
		},
		"Parry",
	) {
		event_dispatch(queue, Event_Fight_Player_Parry{})
	}
}

@(private = "file")
draw_background :: proc(texture: rl.Texture2D) {
	rl.ClearBackground(rl.BLACK)
	aspect := f32(texture.width) / f32(texture.height)
	width: f32 = f32(rl.GetScreenWidth()) + 100
	height: f32 = width / aspect
	rl.DrawTexturePro(
		texture,
		{width = f32(texture.width), height = f32(texture.height)},
		{
			x = -50,
			y = f32(rl.GetScreenHeight()) - FIGHT_LINE - height * 0.8,
			width = width,
			height = height,
		},
		0,
		0,
		rl.WHITE,
	)
}

@(private = "file")
draw_ui_box :: proc() {
	rl.DrawRectangleRec(
		{
			x = 0,
			y = f32(rl.GetScreenHeight()) - UI_HEIGHT,
			width = f32(rl.GetScreenWidth()),
			height = UI_HEIGHT,
		},
		rl.BLACK,
	)
}

@(private = "file")
draw_player_hp :: proc(f: ^World_Fight) {
	font_size :: 32
	text := fmt.ctprintf("HP=%v \nShield=%v", f.player.hp, f.player.shield)
	rl.DrawText(
		text,
		PADDING,
		rl.GetScreenHeight() - UI_HEIGHT - font_size * 2 - PADDING + 100,
		font_size,
		rl.WHITE,
	)
}

@(private = "file")
draw_enemy_hp :: proc(f: ^World_Fight) {
	width :: 300
	height :: 20
	ratio := f32(f.enemy.hp) / f32(f.enemy.max_hp)
	bounds :: proc(ratio: f32) -> rl.Rectangle {
		return rl.Rectangle {
			x = f32(rl.GetScreenWidth()) - width - PADDING,
			y = f32(rl.GetScreenHeight()) - height - UI_HEIGHT - PADDING + 100,
			width = width * ratio,
			height = height,
		}
	}

	rl.DrawRectangleRec(bounds(ratio), rl.RED)
	rl.DrawRectangleLinesEx(bounds(1), 1, rl.WHITE)

	font_size :: 32
	text := fmt.ctprintf("HP: %d/%d", f.enemy.hp, f.enemy.max_hp)
	text_width := rl.MeasureText(text, font_size)
	rl.DrawText(
		text,
		rl.GetScreenWidth() - (width + text_width) / 2 - PADDING,
		rl.GetScreenHeight() - height - font_size - UI_HEIGHT - PADDING + 100,
		font_size,
		rl.WHITE,
	)
}

@(private = "file")
draw_fight_line :: proc() {
	rl.DrawLine(
		0,
		rl.GetScreenHeight() - FIGHT_LINE,
		rl.GetScreenWidth(),
		rl.GetScreenHeight() - FIGHT_LINE,
		rl.BLACK,
	)
}
