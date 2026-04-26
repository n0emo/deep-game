package game

World :: struct {
	state:     World_State,
	overworld: World_Overworld,
	fight:     World_Fight,
}

@(private = "file")
World_State :: enum {
	Overworld,
	Fight,
}

world_make :: proc(assets: ^Assets) -> World {
	return {state = .Overworld, overworld = world_overworld_make(assets), fight = World_Fight{}}
}

world_destroy :: proc(w: ^World) {
	world_overworld_destroy(&w.overworld)
}

world_update :: proc(w: ^World, queue: ^Event_Queue) {
	switch w.state {
	case .Overworld:
		world_overworld_update(&w.overworld, queue)
	case .Fight:
		world_fight_update(&w.fight)
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
		w.fight = world_fight_make(e.hp, e.enemy_name)
	case Event_Fight_Win:
		w.state = .Overworld
	}
}
