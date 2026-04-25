package game

import rl "vendor:raylib"

PlayerStats :: struct {
	alive:  bool,
	shield: int,
	kills:  int,
}

Hud :: struct {
	width:  f32,
	height: f32,
	x:      f32,
	y:      f32,
}

stats: PlayerStats
hud: Hud

hud_init :: proc() {
	stats = PlayerStats {
		alive  = true,
		shield = 3,
		kills  = 0,
	}
	hud = Hud {
		width  = f32(rl.GetScreenWidth()),
		height = f32(rl.GetScreenHeight()),
		x      = 0,
		y      = 0,
	}
}

draw_hp :: proc(g: ^Game_Memory) {
	texture := g.assets.sprites.heart
	pos := rl.Vector2{50, f32(rl.GetScreenHeight()) - 100}
	rl.DrawTextureEx(texture, pos, 0, 9, rl.WHITE)

	texture = g.assets.sprites.shield
	for i in 0 ..< stats.shield {
		pos = rl.Vector2{50 + 85 * (f32(i) + 1), f32(rl.GetScreenHeight()) - 100}
		rl.DrawTextureEx(texture, pos, 0, 9, rl.WHITE)
	}
}

draw_stats :: proc() {
	pos := rl.Vector2{f32(rl.GetScreenWidth()) - 250, f32(rl.GetScreenHeight()) - 80}

	s := rl.TextFormat("Score: %d", stats.kills)
	rl.DrawText(s, i32(pos.x), i32(pos.y), 45, rl.BLACK)
}

draw_hud :: proc(g: ^Game_Memory) {
	draw_stats()
	draw_hp(g)
}
