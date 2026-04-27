package game

import rl "vendor:raylib"

DEFAULT_MASTER_VOLUME :: 0.5
DEFAULT_MUSIC_VOLUME :: 1.0
DEFAULT_SFX_VOLUME :: 1.0

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
		settings = {
			master_volume = DEFAULT_MASTER_VOLUME,
			music_volume = DEFAULT_MUSIC_VOLUME,
			sfx_volume = DEFAULT_SFX_VOLUME,
		},
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
	case Event_Menu:
		switch_music(a, &a.assets.music_menu)
	case Event_Start_Game:
		switch_music(a, &a.assets.music_overworld)
	case Event_Fight_Encounter:
		switch_music(a, &a.assets.jingle_encounter, loop = false)
	case Event_Fight_Begin:
		switch_music(a, &a.assets.music_battle)
	case Event_Fight_Win:
		play_sound(a, a.assets.fx_extra_shield)
		switch_music(a, &a.assets.music_overworld)
	case Event_Change_Audio_Volume:
		a.master_volume = e.master_volume
		a.music_volume = e.music_volume
		a.sfx_volume = e.sfx_volume
	case Event_Button_Pressed:
		play_sound(a, a.assets.fx_button)
	case Event_Player_Moving:
		play_sound(a, a.assets.fx_steps)
	case Event_Fight_Enemy_Warn:
		play_sound(a, a.assets.fx_warning)
	case Event_Fight_Player_Attack_Melee:
		play_sound(a, a.assets.fx_action)
	case Event_Fight_Player_Attack_Range:
		play_sound(a, a.assets.fx_action)
		play_sound(a, a.assets.fx_gunshot)
	case Event_Fight_Player_Parry:
		play_sound(a, a.assets.fx_action)
	case Event_Fight_Player_Deflect:
		play_sound(a, a.assets.fx_action)
	case Event_Fight_Enemy_Take_Hit:
		play_sound(a, a.assets.fx_damage)
		play_sound(a, a.assets.fx_gauntlet)
	case Event_Fight_Enemy_Attack_Ranged:
		play_sound(a, a.assets.fx_projectile)
	case Event_Fight_Player_Get_Hurt:
		play_sound(a, a.assets.fx_damage)
	case Event_Fight_Parry_Success:
		play_sound(a, a.assets.fx_parry)
	case Event_Fight_Deflect_Success:
		play_sound(a, a.assets.fx_deflect)
	case Event_Fight_Enemy_Dead:
		// play_sound(a, a.assets.fx_death)
		switch_music(a, &a.assets.jingle_win, loop = false)
	case Event_End_Transitioning:
		play_sound(a, a.assets.fx_fall)
	case Event_Lose:
		switch_music(a, &a.assets.jingle_dead, loop = false)
	}
}

@(private = "file")
switch_music :: proc(a: ^Audio_System, m: ^rl.Music, loop: bool = true) {
	if a.current_music != nil {
		rl.StopMusicStream(a.current_music^)
	}

	a.current_music = m
	if m != nil {
		m.looping = loop
		rl.PlayMusicStream(m^)
	}
}

@(private = "file")
play_sound :: proc(a: ^Audio_System, s: rl.Sound) {
	rl.SetSoundVolume(s, a.sfx_volume)
	rl.PlaySound(s)
}
