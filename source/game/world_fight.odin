package game

import "core:fmt"
import "core:math/linalg"
import "core:math/rand"
import rl "vendor:raylib"

@(private = "file")
SPRITE_SCALE :: 4

@(private = "file")
UI_HEIGHT :: 250

@(private = "file")
FIGHT_LINE :: UI_HEIGHT + 200

@(private = "file")
BUTTON_SIZE :: rl.Vector2{300, 50}

@(private = "file")
PADDING :: 40

@(private = "file")
BUTTON_GAP :: 10

@(private = "file")
GUYS_PADDING :: 100

@(private = "file")
GUYS_LIMIT :: 50

@(private = "file")
PROJECTILE_SPEED :: 2

@(private = "file")
PROJECTILE_LIMIT :: 10

@(private = "file")
ENEMY_READY_TIME :: 1.5

@(private = "file")
ENEMY_WARN_TIME :: 1

@(private = "file")
ENEMY_ATTACK_VELOCITY :: 0.5

@(private = "file")
PARRY_OFFSET :: 150

@(private = "file")
PARRY_WINDOW_SIZE :: 0.15

@(private = "file")
PARRY_BOUND_HEIGHT :: 100

@(private = "file")
PARRY_LINE_THICKNESS :: 10

@(private = "file")
WIN_JINGLE_TIME :: 2.7

World_Fight :: struct {
	player:                  World_Fight_Player,
	enemy:                   World_Fight_Enemy,
	state:                   Fight_State,
	assets:                  ^Assets,
	projectile_interpolator: f32,
	win_jingle_time:         f32,
}

Fight_State :: enum {
	Player_Turn,
	Player_Attacking_Melee,
	Player_Attacking_Range,
	Player_Taking_Hit,
	Enemy_Turn,
	Enemy_Attacking_Melee,
	Enemy_Attacking_Range,
	Enemy_Taking_Hit,
	Win_Jingle,
}

World_Fight_Player :: struct {
	pos_interpolator:       f32,
	using stats:            ^Player_Stats,
	parry_state:            Player_Parry_State,
	projectile:             Sprite,
	animation_current:      ^Animation,
	animation_idle:         Animation,
	animation_attack_melee: Animation,
	animation_attack_range: Animation,
}

@(private = "file")
Pending_Damage_Melee :: struct {
	damage: int,
}

@(private = "file")
Pending_Damage_Ranged :: struct {
	damage: int,
}

@(private = "file")
Pending_Damage :: union {
	Pending_Damage_Melee,
	Pending_Damage_Ranged,
}

@(private = "file")
Player_Parry_State :: enum {
	Not_Yed_Tried,
	Successfull_Parry,
	Successfull_Deflect,
	Unsuccessfull,
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
	projectile:               Sprite,
	animation_current:        ^Animation,
	animation_idle:           Animation,
	animation_attack_melee:   Animation,
	animation_attack_ranged:  Animation,
	pending:                  Pending_Damage,
}

Turn :: enum {
	Player,
	Enemy,
}

world_fight_make :: proc(
	assets: ^Assets,
	enemy_hp: int,
	enemy_name: string,
	player_stats: ^Player_Stats,
) -> World_Fight {
	player := player_make(assets, player_stats)
	enemy := enemy_make(
		assets,
		enemy_hp,
		enemy_name,
		rl.Vector2{cast(f32)(rl.GetScreenWidth() / 8), 0},
	)
	return {state = .Player_Turn, enemy = enemy, player = player, assets = assets}
}

// TODO: move to something like enemy.odin
// TODO: melee/ranged attack probability
@(private = "file")
enemy_make :: proc(
	assets: ^Assets,
	enemy_hp: int,
	enemy_name: string,
	pos: rl.Vector2,
) -> World_Fight_Enemy {

	enemy := World_Fight_Enemy {
		hp     = enemy_hp,
		max_hp = enemy_hp,
		name   = enemy_name,
	}

	switch enemy_name {
	case "melee":
		enemy.range_damage_reduction = 0.1
		enemy.melee_damage_reduction = 0.1
		enemy.melee_attack_probability = 1
		enemy.melee_damage = 1
		enemy.range_damage = 0
		enemy.animation_idle = assets.animations.enemy_melee_idle
		enemy.animation_attack_melee = assets.animations.enemy_melee_melee_attack
	case "range":
		enemy.melee_damage_reduction = 0.1
		enemy.range_damage_reduction = 0.1
		enemy.melee_attack_probability = 0.0
		enemy.animation_idle = assets.animations.enemy_ranger_idle
		enemy.animation_attack_ranged = assets.animations.enemy_ranger_ranged_attack
		enemy.projectile = assets.sprites.projectile_gear
	case "gear":
		enemy.range_damage_reduction = 0.0
		enemy.melee_damage_reduction = 1.0
		enemy.melee_attack_probability = 1.0
		enemy.melee_damage = 1
		enemy.range_damage = 0
		enemy.animation_idle = assets.animations.enemy_gear_idle
		enemy.animation_attack_melee = assets.animations.enemy_gear_melee_attack
	case "turret":
		enemy.range_damage_reduction = 0.6
		enemy.melee_damage_reduction = 0.2
		enemy.melee_attack_probability = 0.0
		enemy.range_damage = 1
		enemy.melee_damage = 0
		enemy.animation_idle = assets.animations.enemy_turret_idle
		enemy.animation_attack_ranged = assets.animations.enemy_turret_ranged_attack
		enemy.projectile = assets.sprites.projectile_metal_ball
	case "drone":
		enemy.range_damage_reduction = 0.2
		enemy.melee_damage_reduction = 1.0
		enemy.melee_attack_probability = 0.0
		enemy.range_damage = 1
		enemy.melee_damage = 0
		enemy.animation_idle = assets.animations.enemy_drone_idle
		enemy.animation_attack_ranged = assets.animations.enemy_drone_ranged_attack
		enemy.projectile = assets.sprites.projectile_small_bullet
	case "servitor":
		enemy.range_damage_reduction = 0.3
		enemy.melee_damage_reduction = 0.7
		enemy.melee_attack_probability = 0.5
		enemy.range_damage = 1
		enemy.melee_damage = 1
		enemy.animation_idle = assets.animations.enemy_fanatic_idle
		enemy.animation_attack_melee = assets.animations.enemy_fanatic_ranged_attack
		enemy.animation_attack_ranged = assets.animations.enemy_fanatic_melee_attack
		enemy.projectile = assets.sprites.projectile_spikes
	case "last_guardian":
		enemy.range_damage_reduction = 0.5
		enemy.melee_damage_reduction = 0.5
		enemy.melee_attack_probability = 0.5
		enemy.range_damage = 1
		enemy.melee_damage = 1
		enemy.animation_idle = assets.animations.enemy_lastguardian_idle
		enemy.animation_attack_melee = assets.animations.enemy_lastguardian_melee_attack
		enemy.animation_attack_ranged = assets.animations.enemy_lastguardian_ranged_attack
		enemy.projectile = assets.sprites.projectile_sun_core
	}

	return enemy
}

@(private = "file")
enemy_draw :: proc(enemy: ^World_Fight_Enemy) {
	x_end: f32 = GUYS_PADDING + GUYS_LIMIT
	x_start: f32 = f32(rl.GetScreenWidth()) - GUYS_PADDING

	if enemy.animation_current != nil {
		animation_draw(
			enemy.animation_current,
			{
				ease_in_back(x_start, x_end, enemy.pos_interpolator),
				f32(rl.GetScreenHeight()) - FIGHT_LINE,
			},
			centered = true,
			scale = SPRITE_SCALE,
		)
	}
}

@(private = "file")
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

@(private = "file")
player_make :: proc(assets: ^Assets, player_stats: ^Player_Stats) -> World_Fight_Player {
	player := World_Fight_Player {
		stats                  = player_stats,
		projectile             = assets.sprites.projectile_brass_bullet,
		animation_current      = nil,
		animation_idle         = assets.animations.player_fight_idle,
		animation_attack_melee = assets.animations.player_fight_melee_attack,
		animation_attack_range = assets.animations.player_fight_ranged_attack,
	}
	return player
}

@(private = "file")
player_draw :: proc(player: ^World_Fight_Player) {
	x_start: f32 = GUYS_PADDING
	x_end: f32 = f32(rl.GetScreenWidth()) - GUYS_PADDING - GUYS_LIMIT

	if player.animation_current != nil {
		animation_draw(
			player.animation_current,
			{
				ease_in_back(x_start, x_end, player.pos_interpolator),
				f32(rl.GetScreenHeight()) - FIGHT_LINE,
			},
			centered = true,
			scale = SPRITE_SCALE,
		)
	}
}

@(private = "file")
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
	if f.state != .Win_Jingle && f.enemy.hp <= 0 {
		event_dispatch(queue, Event_Fight_Enemy_Dead{})
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
			f.enemy.pending = Pending_Damage_Melee {
				damage = f.player.melee_damage,
			}
			event_dispatch(queue, Event_Fight_Enemy_Take_Hit{})

		}

	case .Player_Attacking_Range:
		f.projectile_interpolator += rl.GetFrameTime() * PROJECTILE_SPEED
		if f.projectile_interpolator > 1 {
			f.projectile_interpolator = 0
			f.enemy.pending = Pending_Damage_Ranged {
				damage = f.player.range_damage,
			}
			event_dispatch(queue, Event_Fight_Enemy_Take_Hit{})
		}
	case .Player_Taking_Hit:
		switch f.player.parry_state {
		case .Not_Yed_Tried:
			fallthrough
		case .Unsuccessfull:
			event_dispatch(queue, Event_Fight_Player_Get_Hurt{})
			rl.TraceLog(.INFO, "Player takes damage")
			if f.player.shield > 0 {
				f.player.shield -= 1
			} else {
				f.player.hp -= 1
			}
		case .Successfull_Parry:
			event_dispatch(queue, Event_Fight_Parry_Success{})
		case .Successfull_Deflect:
			event_dispatch(queue, Event_Fight_Deflect_Success{})
		}
		event_dispatch(queue, Event_Fight_Player_Turn{})

	case .Enemy_Turn:
		f.enemy.ready_time -= rl.GetFrameTime()
		if f.enemy.ready_time < ENEMY_WARN_TIME {
			event_dispatch(queue, Event_Fight_Enemy_Warn{})
		}
		if f.enemy.ready_time < 0 {
			if rand.float32() < f.enemy.melee_attack_probability {
				event_dispatch(queue, Event_Fight_Enemy_Attack_Melee{})
			} else {
				event_dispatch(queue, Event_Fight_Enemy_Attack_Ranged{})
			}
		}

	case .Enemy_Attacking_Melee:
		f.enemy.pos_interpolator += rl.GetFrameTime() * ENEMY_ATTACK_VELOCITY
		if f.enemy.pos_interpolator > 1 {
			f.enemy.pos_interpolator = 0
			event_dispatch(queue, Event_Fight_Player_Take_Hit{})
		}

	case .Enemy_Attacking_Range:
		f.projectile_interpolator += rl.GetFrameTime() * ENEMY_ATTACK_VELOCITY * PROJECTILE_SPEED
		if f.projectile_interpolator > 1 {
			f.projectile_interpolator = 0
			event_dispatch(queue, Event_Fight_Player_Take_Hit{})
		}
	case .Enemy_Taking_Hit:
		switch pen in f.enemy.pending {
		case Pending_Damage_Melee:
			f.enemy.hp -= int(cast(f32)pen.damage * (1 - f.enemy.melee_damage_reduction))
			event_dispatch(queue, Event_Fight_Enemy_Turn{})
		case Pending_Damage_Ranged:
			f.enemy.hp -= int(cast(f32)pen.damage * (1 - f.enemy.range_damage_reduction))
			event_dispatch(queue, Event_Fight_Enemy_Turn{})
		}
	case .Win_Jingle:
		f.win_jingle_time += rl.GetFrameTime()
		if f.win_jingle_time > WIN_JINGLE_TIME {
			event_dispatch(queue, Event_Fight_Win{})
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

@(private = "file")
fight_panel_ui :: proc(f: ^World_Fight, queue: ^Event_Queue) {
	// draw_ui_box()
	draw_enemy_hp(f)
	draw_player_stats(f)

	switch f.state {
	case .Player_Turn:
		ui_player_turn(f, queue)
	case .Player_Attacking_Melee:
	case .Player_Attacking_Range:
		// TODO: Please don't do it like this
		if f.projectile_interpolator > 0 {
			x_start, x_end := projectile_bounds()
			center := rl.Vector2 {
				linalg.lerp(x_start, x_end, f.projectile_interpolator),
				f32(rl.GetScreenHeight()) - FIGHT_LINE - 64,
			}
			sprite_draw(f.player.projectile, center, scale = SPRITE_SCALE, centered = true)
		}
	case .Player_Taking_Hit:
	case .Enemy_Turn:
		if f.enemy.ready_time < ENEMY_WARN_TIME {
			ui_player_defending(f, queue)
		}
	case .Enemy_Attacking_Melee:
		ui_player_defending(f, queue)
	case .Enemy_Attacking_Range:
		x_end, x_start := projectile_bounds()
		center := rl.Vector2 {
			linalg.lerp(x_start, x_end, f.projectile_interpolator),
			f32(rl.GetScreenHeight()) - FIGHT_LINE - 64,
		}
		sprite_draw(
			f.enemy.projectile,
			center,
			scale = SPRITE_SCALE,
			centered = true,
			mirror_horizontal = true,
		)

		ui_player_defending(f, queue)
	case .Enemy_Taking_Hit:
	case .Win_Jingle:
	// nothing
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
			event_dispatch(queue, Event_Fight_Enemy_Dead{})
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
		f.player.parry_state = .Not_Yed_Tried
		f.state = .Enemy_Turn
		f.enemy.ready_time = ENEMY_READY_TIME
	case Event_Fight_Enemy_Attack_Melee:
		f.state = .Enemy_Attacking_Melee
		f.enemy.pos_interpolator = 0
		f.enemy.animation_current = &f.enemy.animation_attack_melee
		animation_reset(f.enemy.animation_current)
	case Event_Fight_Enemy_Attack_Ranged:
		f.state = .Enemy_Attacking_Range
		f.enemy.pos_interpolator = 0
		f.enemy.animation_current = &f.enemy.animation_attack_ranged
		animation_reset(f.enemy.animation_current)
	case Event_Fight_Player_Turn:
		f.state = .Player_Turn
	case Event_Fight_Player_Take_Hit:
		f.state = .Player_Taking_Hit
		f.enemy.animation_current = &f.enemy.animation_idle
		animation_reset(f.enemy.animation_current)
	case Event_Fight_Player_Parry:
		left, right := parry_bounds()
		center := parry_center(f)
		if f.state == .Enemy_Attacking_Melee && left <= center && center <= right {
			f.player.parry_state = .Successfull_Parry
		} else {
			f.player.parry_state = .Unsuccessfull
		}
	case Event_Fight_Player_Deflect:
		left, right := parry_bounds()
		center := parry_center(f)
		if f.state == .Enemy_Attacking_Range && left <= center && center <= right {
			f.player.parry_state = .Successfull_Parry
		} else {
			f.player.parry_state = .Unsuccessfull
		}
	case Event_Fight_Enemy_Take_Hit:
		f.state = .Enemy_Taking_Hit
	case Event_Fight_Enemy_Dead:
		f.state = .Win_Jingle
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
ui_player_defending :: proc(f: ^World_Fight, queue: ^Event_Queue) {
	draw_parry_bounds()
	draw_parry_marker(f)

	if f.player.parry_state == .Not_Yed_Tried {
		if rl.GuiButton(
			{
				x = PADDING,
				y = f32(rl.GetScreenHeight()) - BUTTON_SIZE.y - PADDING,
				width = BUTTON_SIZE.x,
				height = BUTTON_SIZE.y,
			},
			"Parry",
		) {
			event_dispatch(queue, Event_Fight_Player_Parry{})
		}

		if rl.GuiButton(
			{
				x = PADDING,
				y = f32(rl.GetScreenHeight()) - BUTTON_SIZE.y * 2 - BUTTON_GAP - PADDING,
				width = BUTTON_SIZE.x,
				height = BUTTON_SIZE.y,
			},
			"Deflect",
		) {
			event_dispatch(queue, Event_Fight_Player_Deflect{})
		}
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
			y = f32(rl.GetScreenHeight()) - FIGHT_LINE - height * 0.7,
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
draw_player_stats :: proc(f: ^World_Fight) {
	font_size :: 32
	text := fmt.ctprintf(
		"HP:%v      Melee dmg.:%v \nShield:%v Range dmg.:%v",
		f.player.hp,
		f.player.shield,
		f.player.melee_damage,
		f.player.range_damage,
	)
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

@(private = "file")
projectile_bounds :: proc() -> (left: f32, right: f32) {
	left = GUYS_PADDING + PROJECTILE_LIMIT
	right = f32(rl.GetScreenWidth()) - GUYS_PADDING - PROJECTILE_LIMIT
	return
}

@(private = "file")
parry_center :: proc(f: ^World_Fight) -> f32 {
	#partial switch f.state {
	case .Enemy_Attacking_Melee:
		// TODO: deduplicate
		x_end: f32 = GUYS_PADDING + GUYS_LIMIT
		x_start: f32 = f32(rl.GetScreenWidth()) - GUYS_PADDING
		return ease_in_back(x_start, x_end, f.enemy.pos_interpolator)
	case .Enemy_Attacking_Range:
		left, right := projectile_bounds()
		return linalg.lerp(right, left, f.projectile_interpolator)
	case:
		return -100
	}
}

@(private = "file")
parry_bounds :: proc() -> (left: f32, right: f32) {
	length: f32 = f32(rl.GetScreenWidth()) - GUYS_LIMIT * 2
	left = GUYS_LIMIT + PARRY_OFFSET
	right = GUYS_LIMIT + length * PARRY_WINDOW_SIZE + PARRY_OFFSET
	return
}

@(private = "file")
draw_parry_bounds :: proc() {
	left, right := parry_bounds()
	up: f32 = f32(rl.GetScreenHeight()) - FIGHT_LINE + PARRY_BOUND_HEIGHT * 0.5
	down: f32 = f32(rl.GetScreenHeight()) - FIGHT_LINE - PARRY_BOUND_HEIGHT * 0.5

	rl.DrawLineEx({left, up}, {left, down}, PARRY_LINE_THICKNESS, rl.RED)
	rl.DrawLineEx({right, up}, {right, down}, PARRY_LINE_THICKNESS, rl.RED)
}

@(private = "file")
draw_parry_marker :: proc(f: ^World_Fight) {
	x := parry_center(f)
	y := rl.GetScreenHeight() - FIGHT_LINE
	rl.DrawCircle(i32(x), y, 5, rl.BLUE)
}
