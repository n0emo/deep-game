package game

import rl "vendor:raylib"

Input :: struct {}

input_make :: proc() -> Input {
	return {}
}

input_update :: proc(i: ^Input, queue: ^Event_Queue) {
	if rl.IsKeyDown(.UP) || rl.IsKeyDown(.W) {
		event_dispatch(queue, Event_Input_Go{direction = .Up})
	}

	if rl.IsKeyDown(.DOWN) || rl.IsKeyDown(.S) {
		event_dispatch(queue, Event_Input_Go{direction = .Down})
	}

	if rl.IsKeyDown(.LEFT) || rl.IsKeyDown(.A) {
		event_dispatch(queue, Event_Input_Go{direction = .Left})
	}

	if rl.IsKeyDown(.RIGHT) || rl.IsKeyDown(.D) {
		event_dispatch(queue, Event_Input_Go{direction = .Right})
	}
}
