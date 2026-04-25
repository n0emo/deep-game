package game

import rl "vendor:raylib"

Direction :: enum {
	Up,
	Down,
	Left,
	Right,
}

direction_to_vec :: proc(direction: Direction) -> rl.Vector2 {
	switch direction {
	case .Up:
		return {0, -1}
	case .Down:
		return {0, 1}
	case .Left:
		return {-1, 0}
	case .Right:
		return {1, 0}
	case:
		unreachable()
	}
}
