package game

Event_Start_Game :: struct {}

Event_Exit :: struct {}

Event_Menu_Settings :: struct {}

Event_Menu :: struct {}

Event_Menu_Home :: struct {}

Event_Fight_Encounter :: struct {
	using enemy: Object_Enemy,
	obj:         Object,
}

Event_Fight_Begin :: struct {
	using enemy: Object_Enemy,
	obj:         Object,
}

Event_Fight_Win :: struct {}

Event_Fight_Player_Turn :: struct {}

Event_Fight_Enemy_Turn :: struct {}

Event_Change_Audio_Volume :: struct {
	master_volume: f32,
	music_volume:  f32,
	sfx_volume:    f32,
}

Event_Input_Go :: struct {
	direction: Direction,
}

Event_Player_Moving :: struct {}

Event_Player_Stopped :: struct {
	direction: Direction,
}

Event_Transition :: struct {}

Event_Button_Pressed :: struct {}
Event_Fight_Player_Attack_Melee :: struct {
	damage: int,
}

Event_Fight_Player_Attack_Range :: struct {
	damage: int,
}

Event_Fight_Player_Parry :: struct {}

Event_Fight_Player_Deflect :: struct {}

Event_Fight_Enemy_Warn :: struct {}

Event_Fight_Enemy_Attack_Melee :: struct {}

Event_Fight_Enemy_Attack_Ranged :: struct {}

Event_Lose :: struct {}


Event :: union {
	Event_Start_Game,
	Event_Exit,
	Event_Menu,
	Event_Menu_Home,
	Event_Menu_Settings,
	Event_Change_Audio_Volume,
	Event_Input_Go,
	Event_Player_Moving,
	Event_Player_Stopped,
	Event_Fight_Encounter,
	Event_Fight_Begin,
	Event_Lose,
	Event_Fight_Win,
	Event_Fight_Player_Attack_Melee,
	Event_Fight_Player_Attack_Range,
	Event_Fight_Player_Parry,
	Event_Fight_Player_Deflect,
	Event_Fight_Player_Turn,
	Event_Fight_Enemy_Warn,
	Event_Fight_Enemy_Turn,
	Event_Transition,
	Event_Button_Pressed,
	Event_Fight_Enemy_Attack_Melee,
	Event_Fight_Enemy_Attack_Ranged,
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
