package game

import atlas "../atlas"
import "core:math/linalg"
import rl "vendor:raylib"

CAMERA_LERP :: 0.08
PLAYER_SPEED :: 7
PLAYER_NON_IDLE_TIME :: 0.1
ENCOUNTER_TIME :: 0.7
ENCOUNTER_ZOOM_FACTOR :: 12
ENCOUNTER_ROTATION_FACTOR :: 15

BACKGROUND_COLOR := rl.GetColor(0x29211dff)

World_Overworld :: struct {
	tilemap:         Tile_Map,
	player:          Overworld_Player,
	camera:          rl.Camera2D,
	encountering:    bool,
	encounter_state: Encounter_State,
}

world_overworld_make :: proc(assets: ^Assets) -> World_Overworld {
	tilemap, ok := tilemap_make(&assets.tilemap_level_1)
	if !ok {
		panic("Could not load tilemap")
	}
	player_tile := [2]i32{i32(tilemap.spawnpoint.x), i32(tilemap.spawnpoint.y)} / TILE_SIZE
	player := player_make(&assets.sprites.player, player_tile)
	camera := rl.Camera2D{}

	return {tilemap = tilemap, player = player, camera = camera}
}

world_overworld_destroy :: proc(w: ^World_Overworld) {
	tilemap_destroy(&w.tilemap)
}

world_overworld_update :: proc(w: ^World_Overworld, queue: ^Event_Queue) {
	player_update(&w.player, queue)
	world_update_camera(w)

	player_rect := rl.Rectangle{w.player.pos.x, w.player.pos.y, TILE_SIZE, TILE_SIZE}
	if obj, ok := tilemap_is_collides_with_object(&w.tilemap, player_rect); ok {
		switch prop in obj.properties {
		case Object_Spawnpoint:
		// What are you supposed to do with spawnpoint?
		case Object_Transition:
			event_dispatch(queue, Event_Menu{})
		case Object_Enemy:
			event_dispatch(queue, Event_Fight_Encounter{enemy = prop, obj = obj})
			rl.TraceLog(.INFO, "Fight begins with %s", prop.enemy_name)
		}
	}

	if w.encountering {
		s := &w.encounter_state
		s.time += rl.GetFrameTime()
		if s.time >= ENCOUNTER_TIME {
			event_dispatch(queue, Event_Fight_Begin{enemy = s.enemy, obj = s.obj})
			s^ = {}
			w.encountering = false
		}
	}
}

world_overworld_draw :: proc(w: ^World_Overworld) {
	rl.ClearBackground(BACKGROUND_COLOR)
	rl.BeginMode2D(w.camera)
	tilemap_draw(&w.tilemap, rl.Vector2(0))
	player_draw(&w.player)
	rl.EndMode2D()
}

world_overworld_ui :: proc(w: ^World_Overworld, queue: ^Event_Queue) {}

world_overworld_handle_event :: proc(w: ^World_Overworld, event: Event) {
	#partial switch e in event {
	case Event_Fight_Encounter:
		tilemap_delete_object(&w.tilemap, e.obj.id)
		w.encountering = true
		w.encounter_state = encounter_state_make(e)
	case Event_Input_Go:
		if w.encountering {
			return
		}

		next_tile := w.player.tile + direction_to_vec_i32(e.direction)
		if tilemap_tile_passable(&w.tilemap, next_tile) {
			if _, ok := w.player.state.(Player_Idle); ok {
				player_start_moving(&w.player, e.direction)
			}
		} else {
			w.player.direction = e.direction
		}
	}
}

@(private = "file")
Overworld_Player :: struct {
	tile:              [2]i32,
	pos:               rl.Vector2,
	state:             Player_State,
	idle_time:         f32,
	animation_current: ^Animation,
	animations_idle:   [Direction]Animation,
	animations_moving: [Direction]Animation,
	direction:         Direction,
}

@(private = "file")
Player_State :: union {
	Player_Idle,
	Player_Moving,
}

Player_Idle :: struct {}

Player_Moving :: struct {
	start:        rl.Vector2,
	end:          rl.Vector2,
	interpolator: f32,
}

@(private = "file")
player_make :: proc(atlas: ^atlas.Atlas, tile: [2]i32) -> Overworld_Player {
	animations_idle := [Direction]Animation {
		.Up    = animation_make(
			atlas.texture,
			{
				animation_frame_from_atlas(atlas, "player-idle-back-0"),
				animation_frame_from_atlas(atlas, "player-idle-back-1"),
				animation_frame_from_atlas(atlas, "player-idle-back-2"),
				animation_frame_from_atlas(atlas, "player-idle-back-3"),
			},
		),
		.Down  = animation_make(
			atlas.texture,
			{
				animation_frame_from_atlas(atlas, "player-idle-front-0"),
				animation_frame_from_atlas(atlas, "player-idle-front-1"),
				animation_frame_from_atlas(atlas, "player-idle-front-2"),
				animation_frame_from_atlas(atlas, "player-idle-front-3"),
			},
		),
		.Left  = animation_make(
			atlas.texture,
			{
				animation_frame_from_atlas(atlas, "player-idle-left-0"),
				animation_frame_from_atlas(atlas, "player-idle-left-1"),
				animation_frame_from_atlas(atlas, "player-idle-left-2"),
				animation_frame_from_atlas(atlas, "player-idle-left-3"),
			},
		),
		.Right = animation_make(
			atlas.texture,
			{
				animation_frame_from_atlas(atlas, "player-idle-right-0"),
				animation_frame_from_atlas(atlas, "player-idle-right-1"),
				animation_frame_from_atlas(atlas, "player-idle-right-2"),
				animation_frame_from_atlas(atlas, "player-idle-right-3"),
			},
		),
	}

	animations_moving := [Direction]Animation {
		.Up    = animation_make(
			atlas.texture,
			{
				animation_frame_from_atlas(atlas, "player-move-back-0"),
				animation_frame_from_atlas(atlas, "player-move-back-1"),
				animation_frame_from_atlas(atlas, "player-move-back-2"),
				animation_frame_from_atlas(atlas, "player-move-back-3"),
			},
		),
		.Down  = animation_make(
			atlas.texture,
			{
				animation_frame_from_atlas(atlas, "player-move-front-0"),
				animation_frame_from_atlas(atlas, "player-move-front-1"),
				animation_frame_from_atlas(atlas, "player-move-front-2"),
				animation_frame_from_atlas(atlas, "player-move-front-3"),
			},
		),
		.Left  = animation_make(
			atlas.texture,
			{
				animation_frame_from_atlas(atlas, "player-move-left-0"),
				animation_frame_from_atlas(atlas, "player-move-left-1"),
				animation_frame_from_atlas(atlas, "player-move-left-2"),
				animation_frame_from_atlas(atlas, "player-move-left-3"),
			},
		),
		.Right = animation_make(
			atlas.texture,
			{
				animation_frame_from_atlas(atlas, "player-move-right-0"),
				animation_frame_from_atlas(atlas, "player-move-right-1"),
				animation_frame_from_atlas(atlas, "player-move-right-2"),
				animation_frame_from_atlas(atlas, "player-move-right-3"),
			},
		),
	}

	player := Overworld_Player {
		tile              = tile,
		state             = Player_Idle{},
		animations_idle   = animations_idle,
		animations_moving = animations_moving,
		direction         = .Down,
	}

	return player
}

@(private = "file")
player_update :: proc(player: ^Overworld_Player, queue: ^Event_Queue) {
	if player.animation_current == nil {
		player.animation_current = &player.animations_idle[.Down]
	}

	animation_update(player.animation_current)

	player_reset_position(player)

	switch &state in player.state {
	case Player_Idle:
		player.idle_time += rl.GetFrameTime()
		if player.idle_time > PLAYER_NON_IDLE_TIME {
			player.animation_current = &player.animations_idle[player.direction]
		}
	case Player_Moving:
		player.idle_time = 0
		state.interpolator += rl.GetFrameTime() * PLAYER_SPEED
		player.pos = linalg.lerp(state.start, state.end, state.interpolator)
		if state.interpolator >= 1.0 {
			event_dispatch(queue, Event_Player_Stopped{direction = player.direction})
			player.state = Player_Idle{}
		}
	}
}


@(private = "file")
player_draw :: proc(player: ^Overworld_Player) {
	animation_draw(player.animation_current, player.pos)
}

@(private = "file")
player_start_moving :: proc(player: ^Overworld_Player, direction: Direction) {
	dir_vec := direction_to_vec(direction)
	old_tile := player.tile
	new_tile := old_tile + {i32(dir_vec.x), i32(dir_vec.y)}
	player.tile = new_tile
	player.animation_current = &player.animations_moving[direction]
	player.direction = direction
	player.state = Player_Moving {
		start        = {f32(old_tile.x * TILE_SIZE), f32(old_tile.y * TILE_SIZE)},
		end          = {f32(new_tile.x * TILE_SIZE), f32(new_tile.y * TILE_SIZE)},
		interpolator = 0.0,
	}
}

@(private = "file")
player_reset_position :: proc(player: ^Overworld_Player) {
	player.pos = {f32(player.tile.x * TILE_SIZE), f32(player.tile.y * TILE_SIZE)}
}

@(private = "file")
world_update_camera :: proc(w: ^World_Overworld) {
	w.camera.zoom = 6.0 + w.encounter_state.time * ENCOUNTER_ZOOM_FACTOR
	w.camera.rotation = w.encounter_state.time * ENCOUNTER_ROTATION_FACTOR
	w.camera.offset = rl.Vector2{f32(rl.GetScreenWidth()) * 0.5, f32(rl.GetScreenHeight()) * 0.5}
	w.camera.target = linalg.lerp(w.camera.target, w.player.pos, CAMERA_LERP)
}


@(private = "file")
Encounter_State :: struct {
	using event: Event_Fight_Encounter,
	time:        f32,
}

@(private = "file")
encounter_state_make :: proc(event: Event_Fight_Encounter) -> Encounter_State {
	return {event = event, time = 0}
}
