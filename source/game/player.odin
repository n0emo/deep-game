package game

import "../atlas"
import "core:math/linalg"
import rl "vendor:raylib"

Player :: struct {
	pos:       rl.Vector2,
	animation: Animation,
}

player_make :: proc(atlas: ^atlas.Atlas) -> Player {
	animation := animation_make(
		atlas.texture,
		{
			animation_frame_from_atlas(atlas, "player-idle-front-0"),
			animation_frame_from_atlas(atlas, "player-idle-front-1"),
			animation_frame_from_atlas(atlas, "player-idle-front-2"),
			animation_frame_from_atlas(atlas, "player-idle-front-3"),
		},
	)
	return Player{pos = rl.Vector2(0), animation = animation}
}

player_update :: proc(player: ^Player) {
	animation_update(&player.animation)
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
	animation_draw(&player.animation, player.pos)
}
