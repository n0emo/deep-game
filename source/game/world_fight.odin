package game

import "core:fmt"
import rl "vendor:raylib"

World_Fight :: struct {
	enemy_hp:   int,
	enemy_name: string,
}

world_fight_make :: proc(enemy_hp: int, enemy_name: string) -> World_Fight {
	return {enemy_hp = enemy_hp, enemy_name = enemy_name}
}

world_fight_update :: proc(f: ^World_Fight) {}

world_fight_draw :: proc(f: ^World_Fight) {
	rl.ClearBackground(rl.BEIGE)
}

world_fight_ui :: proc(f: ^World_Fight, queue: ^Event_Queue) {
	text := fmt.ctprintf("Enemy: name=%v hp=%v", f.enemy_name, f.enemy_hp)
	text_centered(text, 32, {0, -100})
	if button_centered("Press to win", {400, 50}, {0, 0}) {
		event_dispatch(queue, Event_Fight_Win{})
	}
}

world_fight_handle_event :: proc(f: ^World_Fight, event: Event) {}
