package game

World :: struct {
	state:           World_State,
	overworld:       World_Overworld,
	fight:           World_Fight,
	tilemaps:        [2]Tile_Map,
	current_tilemap: int,
	assets:          ^Assets,
}

@(private = "file")
World_State :: enum {
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

	world := new(World)
	world^ = {
		state           = .Overworld,
		tilemaps        = tilemaps,
		current_tilemap = 0,
		assets          = assets,
	}
	world.overworld = world_overworld_make(assets, &world.tilemaps[0])

	return world
}

world_destroy :: proc(w: ^World) {
	world_overworld_destroy(&w.overworld)
	free(w)
}

world_update :: proc(w: ^World, queue: ^Event_Queue) {
	if w.current_tilemap == len(w.tilemaps) {
		event_dispatch(queue, Event_Menu{})
		return
	}

	switch w.state {
	case .Overworld:
		world_overworld_update(&w.overworld, queue)
	case .Fight:
		world_fight_update(&w.fight, queue)
	}
}

world_draw :: proc(w: ^World) {
	switch w.state {
	case .Overworld:
		world_overworld_draw(&w.overworld)
	case .Fight:
		world_fight_draw(&w.fight)
	}
}

world_ui :: proc(w: ^World, queue: ^Event_Queue) {
	switch w.state {
	case .Overworld:
		world_overworld_ui(&w.overworld, queue)
	case .Fight:
		world_fight_ui(&w.fight, queue)
	}
}

world_handle_event :: proc(w: ^World, event: Event) {
	switch w.state {
	case .Overworld:
		world_overworld_handle_event(&w.overworld, event)
	case .Fight:
		world_fight_handle_event(&w.fight, event)
	}

	#partial switch e in event {
	case Event_Fight_Begin:
		w.state = .Fight
		w.fight = world_fight_make(w.assets, e.hp, e.enemy_name)
	case Event_Fight_Win:
		w.state = .Overworld
	case Event_Transition:
		w.current_tilemap += 1
		if w.current_tilemap < len(w.tilemaps) {
			w.overworld = world_overworld_make(w.assets, &w.tilemaps[w.current_tilemap])
		}
	}
}
