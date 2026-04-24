package game

import "core:math/linalg"
import rl "vendor:raylib"

Player :: struct {
	pos:     rl.Vector2,
	texture: rl.Texture2D,
}

player_make :: proc(texture: rl.Texture2D) -> Player {
	return Player{pos = rl.Vector2(0), texture = texture}
}

player_update :: proc(player: ^Player) {
	input: rl.Vector2

	if rl.IsKeyDown(.UP) || rl.IsKeyDown(.W) {
		input.y -= 1
	}
	if rl.IsKeyDown(.DOWN) || rl.IsKeyDown(.S) {
		input.y += 1
	}
	if rl.IsKeyDown(.LEFT) || rl.IsKeyDown(.A) {
		input.x -= 1
	}
	if rl.IsKeyDown(.RIGHT) || rl.IsKeyDown(.D) {
		input.x += 1
	}

	input = linalg.normalize0(input)
	player.pos += input * rl.GetFrameTime() * 100
}

player_draw :: proc(player: ^Player) {
	rl.DrawTextureEx(player.texture, player.pos, 0, 1, rl.WHITE)
}
