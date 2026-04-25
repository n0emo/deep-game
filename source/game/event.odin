package game

Event_Start_Game :: struct {}

Event_Exit :: struct {}

Event_Menu_Settings :: struct {}

Event_Menu :: struct {}

Event_Menu_Home :: struct {}

Event_Fight :: struct {}

Event_Fight_Player_Turn :: struct {}

Event_Fight_Enemy_Turn :: struct {}

Event_Change_Master_Volume :: struct {
	volume: f32,
}

Event_Change_Music_Volume :: struct {
	volume: f32,
}

Event_Change_Sfx_Volume :: struct {
	volume: f32,
}

Event_Input_Go :: struct {
	direction: Direction,
}

Event_Player_Stopped :: struct {
	direction: Direction,
}

Event :: union {
	Event_Start_Game,
	Event_Exit,
	Event_Menu,
	Event_Menu_Home,
	Event_Menu_Settings,
	Event_Change_Master_Volume,
	Event_Change_Music_Volume,
	Event_Change_Sfx_Volume,
	Event_Input_Go,
	Event_Player_Stopped,
	Event_Fight,
	Event_Fight_Player_Turn,
	Event_Fight_Enemy_Turn,
}

Event_Queue :: struct {
	queue: [dynamic]Event,
}

event_dispatch :: proc(queue: ^Event_Queue, event: Event) {
	append(&queue.queue, event)
}

event_pop :: proc(queue: ^Event_Queue) -> (event: Event, ok: bool) {
	if len(queue.queue) == 0 {
		return nil, false
	}
	return pop_dynamic_array(&queue.queue), true
}
