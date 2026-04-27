package game

import "core:math/rand"
import rl "vendor:raylib"


World :: struct {
	state:           World_State,
	transition:      World_Transitioning,
	overworld:       World_Overworld,
	fight:           World_Fight,
	tilemaps:        [2]Tile_Map,
	current_tilemap: int,
	assets:          ^Assets,
	player_stats:    Player_Stats,
}

Player_Stats :: struct {
	hp:           int,
	shield:       int,
	melee_damage: int,
	range_damage: int,
}

@(private = "file")
World_State :: enum {
	Transitioning,
	Overworld,
	Fight,
}

world_make :: proc(assets: ^Assets) -> ^World {
	tilemap_1: Tile_Map
	tilemap_2: Tile_Map
	ok: bool
	tilemap_1, ok = tilemap_make(&assets.tilemap_level_1)
	tilemap_2, ok = tilemap_make(&assets.tilemap_level_2)
	if !ok {
		panic("Could not load tilemap")
	}

	tilemaps := [2]Tile_Map{tilemap_1, tilemap_2}

	player_stats := Player_Stats {
		hp           = 10,
		shield       = 3,
		melee_damage = 3,
		range_damage = 3,
	}
	world := new(World)
	world^ = {
		state           = .Transitioning,
		transition      = world_transitioning_make(assets),
		tilemaps        = tilemaps,
		current_tilemap = -1,
		assets          = assets,
		player_stats    = player_stats,
	}
	world.overworld = world_overworld_make(assets, &world.tilemaps[0], world.current_tilemap + 1)

	return world
}

world_destroy :: proc(w: ^World) {
	world_transitioning_destroy(&w.transition)
	world_overworld_destroy(&w.overworld)
	free(w)
}

world_update :: proc(w: ^World, queue: ^Event_Queue) {
	if w.current_tilemap == len(w.tilemaps) {
		event_dispatch(queue, Event_Win{})
		return
	}

	switch w.state {
	case .Overworld:
		world_overworld_update(&w.overworld, queue)
	case .Fight:
		world_fight_update(&w.fight, queue)
	case .Transitioning:
		world_transitioning_update(&w.transition, queue)
	}
}

world_draw :: proc(w: ^World) {
	switch w.state {
	case .Overworld:
		world_overworld_draw(&w.overworld)
	case .Fight:
		world_fight_draw(&w.fight)
	case .Transitioning:
		world_transitioning_draw(&w.transition)
	}
}

world_ui :: proc(w: ^World, queue: ^Event_Queue) {
	switch w.state {
	case .Overworld:
		world_overworld_ui(&w.overworld, queue)
	case .Fight:
		world_fight_ui(&w.fight, queue)
	case .Transitioning:
		world_transitioning_ui(&w.transition, queue)
	}
}

world_handle_event :: proc(w: ^World, event: Event) {
	switch w.state {
	case .Overworld:
		world_overworld_handle_event(&w.overworld, event)
	case .Fight:
		world_fight_handle_event(&w.fight, event)
	case .Transitioning:
		world_transitioning_handle_event(&w.transition, event)
	}

	#partial switch e in event {
	case Event_Fight_Begin:
		w.state = .Fight
		w.fight = world_fight_make(w.assets, e.hp, e.enemy_name, &w.player_stats)
	case Event_Fight_Win:
		rng := rand.int_max(2)
		rl.TraceLog(.INFO, "%d", rng)
		switch rng {
		case 0:
			w.fight.player.melee_damage += 2
		case 1:
			w.fight.player.range_damage += 2
		}
		w.fight.player.shield += 1
		w.state = .Overworld
	case Event_Transition:
		w.state = .Transitioning
		w.transition = world_transitioning_make(w.assets)
	case Event_End_Transitioning:
		w.current_tilemap += 1
		if w.current_tilemap < len(w.tilemaps) {
			w.overworld = world_overworld_make(
				w.assets,
				&w.tilemaps[w.current_tilemap],
				w.current_tilemap + 1,
			)
		}
		w.state = .Overworld
	}
}
