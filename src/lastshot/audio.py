from __future__ import annotations
from lastshot.assets import AssetsAudio
import pyray as rl
from .events import (
    ButtonPressedEvent,
    EndTransitioningEvent,
    Event,
    ChangeAudioVolumeEvent,
    FightBeginEvent,
    FightDeflectSuccessEvent,
    FightEncounterEvent,
    FightEnemyAttackMeleeEvent,
    FightEnemyAttackRangedEvent,
    FightEnemyDeadEvent,
    FightEnemyTakeHitEvent,
    FightEnemyWarnPleaseEvent,
    FightParrySuccessEvent,
    FightPlayerDeflectEvent,
    FightPlayerGetHurtEvent,
    FightPlayerParryEvent,
    FightWinEvent,
    LoseEvent,
    MenuEvent,
    PlayerMovingEvent,
    StartGameEvent,
    WinEvent,
)
from .scenes import Scene

DEFAULT_MASTER_VOLUME = 0.5
DEFAULT_MUSIC_VOLUME = 1.0
DEFAULT_SFX_VOLUME = 1.0


class AudioSystem:
    __current_music: rl.Music | None
    __audio: AssetsAudio
    __master_volume: float
    __music_volume: float
    __sfx_volume: float

    def __init__(self, audio: AssetsAudio) -> None:
        self.__current_music = None
        self.__audio = audio
        self.__master_volume = DEFAULT_MASTER_VOLUME
        self.__music_volume = DEFAULT_MUSIC_VOLUME
        self.__sfx_volume = DEFAULT_SFX_VOLUME

    @property
    def master_volume(self) -> float:
        return self.__master_volume

    @property
    def music_volume(self) -> float:
        return self.__music_volume

    @property
    def sfx_volume(self) -> float:
        return self.__sfx_volume

    def update(self) -> None:
        rl.set_master_volume(self.__master_volume)
        if self.__current_music is not None:
            rl.set_music_volume(self.__current_music, self.__music_volume)
            rl.update_music_stream(self.__current_music)

    def handle_event(self, event: Event) -> None:
        match event:
            case MenuEvent():
                self.switch_music(self.__audio.music_menu)
            case StartGameEvent():
                self.switch_music(self.__audio.music_overworld)
            case FightEncounterEvent():
                self.switch_music(self.__audio.jingle_encounter, loop=False)
            case FightBeginEvent():
                self.switch_music(self.__audio.music_battle)
            case FightWinEvent():
                self.play_sound(self.__audio.fx_extra_shield)
                self.switch_music(self.__audio.music_overworld)
            case ChangeAudioVolumeEvent():
                self.__master_volume = event.master_volume
                self.__music_volume = event.music_volume
                self.__sfx_volume = event.sfx_volume
            case ButtonPressedEvent():
                self.play_sound(self.__audio.fx_button)
            case PlayerMovingEvent():
                self.play_sound(self.__audio.fx_steps)
            case FightEnemyWarnPleaseEvent():
                self.play_sound(self.__audio.fx_warning)
            case FightEnemyAttackMeleeEvent():
                self.play_sound(self.__audio.fx_action)
            case FightEnemyAttackRangedEvent():
                self.play_sound(self.__audio.fx_action)
                self.play_sound(self.__audio.fx_gunshot)
            case FightPlayerParryEvent():
                self.play_sound(self.__audio.fx_action)
            case FightPlayerDeflectEvent():
                self.play_sound(self.__audio.fx_action)
            case FightEnemyTakeHitEvent():
                self.play_sound(self.__audio.fx_damage)
                self.play_sound(self.__audio.fx_gauntlet)
            case FightEnemyAttackRangedEvent():
                self.play_sound(self.__audio.fx_projectile)
            case FightPlayerGetHurtEvent():
                self.play_sound(self.__audio.fx_damage)
            case FightParrySuccessEvent():
                self.play_sound(self.__audio.fx_parry)
            case FightDeflectSuccessEvent():
                self.play_sound(self.__audio.fx_deflect)
            case FightEnemyDeadEvent():
                self.play_sound(self.__audio.fx_death)
                self.switch_music(self.__audio.jingle_win, loop=False)
            case EndTransitioningEvent():
                self.play_sound(self.__audio.fx_fall)
            case LoseEvent():
                self.switch_music(self.__audio.jingle_dead, loop=False)
            case WinEvent():
                self.switch_music(self.__audio.jingle_win, loop=False)

    def subscribe_all(self, scene: Scene) -> None:
        for event_type in [
            ButtonPressedEvent,
            EndTransitioningEvent,
            Event,
            ChangeAudioVolumeEvent,
            FightBeginEvent,
            FightDeflectSuccessEvent,
            FightEncounterEvent,
            FightEnemyAttackMeleeEvent,
            FightEnemyAttackRangedEvent,
            FightEnemyDeadEvent,
            FightEnemyTakeHitEvent,
            FightEnemyWarnPleaseEvent,
            FightParrySuccessEvent,
            FightPlayerDeflectEvent,
            FightPlayerGetHurtEvent,
            FightPlayerParryEvent,
            FightWinEvent,
            LoseEvent,
            MenuEvent,
            PlayerMovingEvent,
            StartGameEvent,
            WinEvent,
        ]:
            scene.subscribe(event_type, self.handle_event)

    def switch_music(self, music: rl.Music, loop: bool = True) -> None:
        if self.__current_music is not None:
            rl.stop_music_stream(self.__current_music)
        self.__current_music = music
        music.looping = loop
        rl.play_music_stream(music)

    def play_sound(self, sound: rl.Sound) -> None:
        rl.set_sound_volume(sound, self.__sfx_volume)
        rl.play_sound(sound)
