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

world_update :: proc(w: ^World) {
	switch w.state {
	case .Overworld:
		world_overworld_update(&w.overworld)
	case .Fight:
	}
}

world_draw :: proc(w: ^World) {
	switch w.state {
	case .Overworld:
		world_overworld_draw(&w.overworld)
	case .Fight:
	}
}

world_ui :: proc(w: ^World, queue: ^Event_Queue) {}

world_handle_event :: proc(w: ^World, event: Event) {}
