package game

import "core:math/linalg"

ease_in_expo :: proc(a, b, t: $T) -> T {
	t := t
	if t != 0 {
		t = math.pow(2, 10 * t - 10)
	}
	return linalg.lerp(a, b, t)
}

ease_in_back :: proc(a, b, t: $T) -> T {
	t := t
	// c1 :: 1.70158
	// c3 :: c1 + 1

	t = t * t
	// t = c3 * t * t * t - c1 * t * t
	return linalg.lerp(a, b, t)
}
