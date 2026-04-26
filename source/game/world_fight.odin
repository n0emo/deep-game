package game

import atlas "../atlas"
import "core:fmt"
import rl "vendor:raylib"

World_Fight :: struct {
	player: World_Fight_Player,
	enemy:  World_Fight_Enemy,
	state:  Fight_State,
	assets: ^Assets,
}

Fight_State :: enum {
	Player_Turn,
	Player_Attacking,
	Enemy_Attacking,
}

World_Fight_Player :: struct {
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
	hp:                     int,
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
	pattern:                []Event,
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
		animation_draw(enemy.animation_current, enemy.pos)
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
	if player.animation_current != nil {
		animation_draw(player.animation_current, {0, 0})
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
}

world_fight_draw :: proc(f: ^World_Fight) {
	rl.ClearBackground(rl.BEIGE)
	rl.BeginMode2D(rl.Camera2D{zoom = 6})
	player_draw(&f.player)
	enemy_draw(&f.enemy)
	rl.EndMode2D()
	player_info := fmt.ctprintf("HP=%v \nShield=%v", f.player.hp, f.player.shield)
	text_centered(player_info, 32, {cast(f32)(-rl.GetScreenWidth() / 2 + 200), -200})
	enemy_info := fmt.ctprintf("Enemy:%v HP=%v", f.enemy.name, f.enemy.hp)
	text_centered(enemy_info, 32, {cast(f32)(rl.GetScreenWidth() / 2 - 200), -200})
}

world_fight_ui :: proc(f: ^World_Fight, queue: ^Event_Queue) {
	fight_panel_ui(f, queue)
}

fight_panel_ui :: proc(f: ^World_Fight, queue: ^Event_Queue) {
	rl.DrawRectangle(
		0,
		rl.GetScreenHeight() * 35 / 100,
		rl.GetScreenWidth(),
		rl.GetScreenHeight() * 65 / 100,
		rl.GRAY,
	)
	switch f.state {
	case .Player_Turn:
		text_centered("Your turn", 32, {0, -200})
		if button_centered(
			"Attack Melee",
			{300, 50},
			{cast(f32)(-rl.GetScreenWidth() / 2 + 200), 0},
		) {
			event_dispatch(queue, Event_Fight_Player_Attack_Melee{damage = f.player.melee_damage})
		}
		if button_centered(
			"Attack Range",
			{300, 50},
			{cast(f32)(-rl.GetScreenWidth() / 2 + 200), 50},
		) {
			event_dispatch(queue, Event_Fight_Player_Attack_Range{damage = f.player.range_damage})
		}
		if f.player.animation_current.index == len(f.player.animation_current.frames) {
			event_dispatch(queue, Event_Fight_Player_Turn{})
		}

	case .Player_Attacking:
		if f.player.animation_current.index == len(f.player.animation_current.frames) - 1 {
			rl.TraceLog(.INFO, "Player turn ended")
			event_dispatch(queue, Event_Fight_Enemy_Turn{})
		}

	case .Enemy_Attacking:
		text_centered("Enemy's turn", 32, {0, 50})
		event_dispatch(queue, Event_Fight_Enemy_Attack_Melee{})
		if (rl.IsKeyPressed(rl.KeyboardKey.J)) {
			event_dispatch(queue, Event_Fight_Player_Parry{})
		}
		if (rl.IsKeyPressed(rl.KeyboardKey.K)) {
			event_dispatch(queue, Event_Fight_Player_Parry{})
		}
		if button_centered(
			"Parry(for melee attack)",
			{300, 50},
			{cast(f32)(-rl.GetScreenWidth() / 2 + 200), 0},
		) {
			event_dispatch(queue, Event_Fight_Player_Parry{})
		}
		if button_centered(
			"Deflect(for ranged attack)",
			{300, 100},
			{cast(f32)(-rl.GetScreenWidth() / 2 + 200), 0},
		) {
			event_dispatch(queue, Event_Fight_Player_Deflect{})
		}
		if f.enemy.animation_current.index == len(f.enemy.animation_current.frames) - 1 {
			event_dispatch(queue, Event_Fight_Player_Turn{})
			rl.TraceLog(.INFO, "Enemy turn ended")

		}
	}
	// Delete this on release
	if button_centered(
		"Press to win",
		{300, 50},
		{cast(f32)(-rl.GetScreenWidth() / 2 + 200), 100},
	) {
		event_dispatch(queue, Event_Fight_Win{})
	}
}

world_fight_handle_event :: proc(f: ^World_Fight, event: Event) {
	#partial switch e in event {
	case Event_Fight_Player_Attack_Melee:
		if f.state != .Player_Turn {
			return
		}
		f.player.animation_current = &f.player.animation_attack_melee
		animation_reset(&f.player.animation_attack_melee)
		f.enemy.hp = max(0, f.enemy.hp - e.damage)
		f.state = .Player_Attacking

	case Event_Fight_Player_Attack_Range:
		if f.state != .Player_Turn {
			return
		}
		f.player.animation_current = &f.player.animation_attack_range
		animation_reset(&f.player.animation_attack_range)
		f.enemy.hp = max(0, f.enemy.hp - e.damage)
		f.state = .Player_Attacking

	case Event_Fight_Enemy_Attack_Melee:
		if f.state != .Enemy_Attacking {
			return
		}
		f.enemy.animation_current = &f.enemy.animation_attack_melee
		animation_reset(&f.enemy.animation_attack_melee)

		if f.player.shield > 0 {
			f.player.shield = max(0, f.player.shield - f.enemy.melee_damage)
		} else {
			f.player.hp = max(0, f.player.hp - f.enemy.melee_damage)
		}
	case Event_Fight_Enemy_Attack_Range:
		if f.state != .Enemy_Attacking {
			return
		}
		f.enemy.animation_current = &f.enemy.animation_attack_range
		animation_reset(&f.enemy.animation_attack_range)

		if f.player.shield > 0 {
			f.player.shield = max(0, f.player.shield - f.enemy.range_damage)
		} else {
			f.player.hp = max(0, f.player.hp - f.enemy.range_damage)
		}
	case Event_Fight_Player_Parry:
		if f.state != .Enemy_Attacking {
			return
		}
	case Event_Fight_Player_Deflect:
		if f.state != .Enemy_Attacking {
			return
		}
	case Event_Fight_Enemy_Turn:
		f.state = .Enemy_Attacking
	case Event_Fight_Player_Turn:
		f.state = .Player_Turn

	}

}
