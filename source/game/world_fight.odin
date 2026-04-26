package game

import atlas "../atlas"
import "core:fmt"
import "core:math/linalg"
import rl "vendor:raylib"

@(private = "file")
UI_HEIGHT :: 300

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
	pos_interpolator:       f32,
	hp:                     int,
	max_hp:                 int,
	name:                   string,
	melee_damage:           int,
	range_damage:           int,
	melee_damage_reduction: f32,
	range_damage_reduction: f32,
	animation_current:      ^Animation,
	animation_idle:         Animation,
	animation_attack_melee: Animation,
	animation_attack_range: Animation,
	pos:                    rl.Vector2,
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

enemy_draw :: proc(enemy: ^World_Fight_Enemy) {
	if enemy.animation_current != nil {
		animation_draw(
			enemy.animation_current,
			{f32(rl.GetScreenWidth()) - GUYS_PADDING, f32(rl.GetScreenHeight()) - FIGHT_LINE},
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
			event_dispatch(queue, Event_Fight_Player_Turn{})
		}
	case .Player_Attacking_Range:
		f.projectile_interpolator += rl.GetFrameTime() * PROJECTILE_SPEED
		if f.projectile_interpolator > 1 {
			f.projectile_interpolator = 0
			event_dispatch(queue, Event_Fight_Player_Turn{})
		}
	case .Enemy_Turn:
	case .Enemy_Attacking_Melee:
	case .Enemy_Attacking_Range:
	}
}

world_fight_draw :: proc(f: ^World_Fight) {
	rl.ClearBackground(rl.BEIGE)
	player_draw(&f.player)
	enemy_draw(&f.enemy)
}

world_fight_ui :: proc(f: ^World_Fight, queue: ^Event_Queue) {
	fight_panel_ui(f, queue)
}

fight_panel_ui :: proc(f: ^World_Fight, queue: ^Event_Queue) {
	f.enemy.hp = 500
	draw_ui_box()
	draw_enemy_hp(f)
	draw_player_hp(f)

	// #partial switch f.state {
	// case .Player_Turn:
	//
	// case .Player_Attacking:
	// 	if f.player.animation_current.index == len(f.player.animation_current.frames) - 1 {
	// 		rl.TraceLog(.INFO, "Player turn ended")
	// 		event_dispatch(queue, Event_Fight_Enemy_Turn{})
	// 	}
	//
	// case .Enemy_Attacking:
	// 	text_centered("Enemy's turn", 32, {0, 50})
	// 	event_dispatch(queue, Event_Fight_Enemy_Attack_Melee{})
	// 	if (rl.IsKeyPressed(rl.KeyboardKey.J)) {
	// 		event_dispatch(queue, Event_Fight_Player_Parry{})
	// 	}
	// 	if (rl.IsKeyPressed(rl.KeyboardKey.K)) {
	// 		event_dispatch(queue, Event_Fight_Player_Parry{})
	// 	}
	// 	if button_centered(
	// 		"Parry(for melee attack)",
	// 		{300, 50},
	// 		{cast(f32)(-rl.GetScreenWidth() / 2 + 200), 0},
	// 	) {
	// 		event_dispatch(queue, Event_Fight_Player_Parry{})
	// 	}
	// 	if button_centered(
	// 		"Deflect(for ranged attack)",
	// 		{300, 100},
	// 		{cast(f32)(-rl.GetScreenWidth() / 2 + 200), 0},
	// 	) {
	// 		event_dispatch(queue, Event_Fight_Player_Deflect{})
	// 	}
	// 	if f.enemy.animation_current.index == len(f.enemy.animation_current.frames) - 1 {
	// 		event_dispatch(queue, Event_Fight_Player_Turn{})
	// 		rl.TraceLog(.INFO, "Enemy turn ended")
	//
	// 	}
	// }
	// Delete this on release
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
			4,
			rl.RED,
		)
	case .Enemy_Turn:
	case .Enemy_Attacking_Melee:
	case .Enemy_Attacking_Range:
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
	// 	f.state = .Player_Attacking
	//
	// case Event_Fight_Enemy_Attack_Melee:
	// 	if f.state != .Enemy_Attacking {
	// 		return
	// 	}
	// 	f.enemy.animation_current = &f.enemy.animation_attack_melee
	// 	animation_reset(&f.enemy.animation_attack_melee)
	//
	// 	if f.player.shield > 0 {
	// 		f.player.shield = max(0, f.player.shield - f.enemy.melee_damage)
	// 	} else {
	// 		f.player.hp = max(0, f.player.hp - f.enemy.melee_damage)
	// 	}
	// case Event_Fight_Enemy_Attack_Range:
	// 	if f.state != .Enemy_Attacking {
	// 		return
	// 	}
	// 	f.enemy.animation_current = &f.enemy.animation_attack_range
	// 	animation_reset(&f.enemy.animation_attack_range)
	//
	// 	if f.player.shield > 0 {
	// 		f.player.shield = max(0, f.player.shield - f.enemy.range_damage)
	// 	} else {
	// 		f.player.hp = max(0, f.player.hp - f.enemy.range_damage)
	// 	}
	// case Event_Fight_Player_Parry:
	// 	if f.state != .Enemy_Attacking {
	// 		return
	// 	}
	// case Event_Fight_Player_Deflect:
	// 	if f.state != .Enemy_Attacking {
	// 		return
	// 	}
	// case Event_Fight_Enemy_Turn:
	// 	f.state = .Enemy_Attacking
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

@(private = "file")
draw_ui_box :: proc() {
	rl.DrawRectangleRec(
		{
			x = 0,
			y = f32(rl.GetScreenHeight()) - UI_HEIGHT,
			width = f32(rl.GetScreenWidth()),
			height = UI_HEIGHT,
		},
		rl.WHITE,
	)
}

@(private = "file")
draw_player_hp :: proc(f: ^World_Fight) {
	font_size :: 32
	text := fmt.ctprintf("HP=%v \nShield=%v", f.player.hp, f.player.shield)
	rl.DrawText(
		text,
		PADDING,
		rl.GetScreenHeight() - UI_HEIGHT - font_size * 2 - PADDING,
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
			y = f32(rl.GetScreenHeight()) - height - UI_HEIGHT - PADDING,
			width = width * ratio,
			height = height,
		}
	}

	rl.DrawRectangleRec(bounds(ratio), rl.RED)
	rl.DrawRectangleLinesEx(bounds(1), 1, rl.BLACK)

	font_size :: 32
	text := fmt.ctprintf("HP: %d/%d", f.enemy.hp, f.enemy.max_hp)
	text_width := rl.MeasureText(text, font_size)
	rl.DrawText(
		text,
		rl.GetScreenWidth() - (width + text_width) / 2 - PADDING,
		rl.GetScreenHeight() - height - font_size - UI_HEIGHT - PADDING,
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
