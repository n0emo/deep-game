package game

import "core:math"
import "core:math/linalg"

ease_in_expo :: proc(a, b, t: $T) -> T {
	t := t
	if t != 0 {
		t = math.pow(2, 10 * t - 10)
	}
	return linalg.lerp(a, b, t)
}

ease_in_out_back :: proc(a, b, t: $T) -> T {
	c1 :: 1.70158
	c2 :: c1 * 1.525

	t := t
	if t < 0.5 {
		t = (math.pow(2 * t, 2) * ((c2 + 1) * 2 * t - c2)) / 2
	} else {
		t = (math.pow(2 * t - 2, 2) * ((c2 + 1) * (t * 2 - 2) + c2) + 2) / 2
	}

	return linalg.lerp(a, b, t)

}
