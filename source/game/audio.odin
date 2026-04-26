package game

import rl "vendor:raylib"

Audio_System :: struct {
	current_music:  ^rl.Music,
	assets:         ^Assets_Audio,
	using settings: Audio_Settings,
}

Audio_Settings :: struct {
	master_volume: f32,
	music_volume:  f32,
	sfx_volume:    f32,
}

audio_system_make :: proc(assets: ^Assets) -> Audio_System {
	return {
		current_music = nil,
		assets = &assets.audio,
		settings = {master_volume = 0.5, music_volume = 1.0, sfx_volume = 1.0},
	}
}

audio_system_update :: proc(a: ^Audio_System) {
	rl.SetMasterVolume(a.master_volume)
	if a.current_music != nil {
		rl.SetMusicVolume(a.current_music^, a.music_volume)
		rl.UpdateMusicStream(a.current_music^)
	}
}

audio_system_handle_event :: proc(a: ^Audio_System, event: Event) {
	#partial switch e in event {
	case Event_Fight_Begin:
		rl.TraceLog(.INFO, "Playing battle music")
		switch_music(a, &a.assets.music_battle)
	case Event_Fight_Win:
		switch_music(a, nil)
    case Event_Change_Master_Volume:
        a.settings = {master_volume = e.volume}
    case Event_Change_Music_Volume:
        a.settings = {music_volume = e.volume}
    case Event_Change_Sfx_Volume:
        a.settings = {sfx_volume = e.volume}
    }
}

@(private = "file")
switch_music :: proc(a: ^Audio_System, m: ^rl.Music) {
	if a.current_music != nil {
		rl.StopMusicStream(a.current_music^)
	}

	a.current_music = m
	if m != nil {
		rl.PlayMusicStream(m^)
		rl.SeekMusicStream(m^, 0)
	}
}
