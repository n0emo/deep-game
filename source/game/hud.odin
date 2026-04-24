package game

import rl "vendor:raylib"

PlayerStats :: struct {
    alive : bool,
    shield : int,
    kills : int,
}

Hud :: struct {
	width:  f32,
	height: f32,
	x:      f32,
	y:      f32,
}

stats : PlayerStats
window : Hud

hud_init :: proc() {
    stats = PlayerStats {
        alive = true,
        shield = 0,
        kills = 0,
    }
    window = Hud {
        width = f32(rl.GetScreenWidth()),
        height = f32(rl.GetScreenHeight()),
        x = 0,
        y = 0,
    }
}

draw_hud :: proc() {
	width: f32 = f32(rl.GetScreenWidth()) / 1.8
	height: f32 = f32(rl.GetScreenHeight()) / 1.8
	x := f32(rl.GetScreenWidth()) / 2.0 - width / 2.0
	y := f32(rl.GetScreenHeight()) / 2.0 - height / 2.0


	rl.BeginDrawing()
	rec := rl.Rectangle{x, y, width, height}
    
	rl.DrawRectangleRounded(rec, 0.2, 3, rl.Fade(rl.BLACK, 0.7))
}
