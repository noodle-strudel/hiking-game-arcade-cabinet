extends Node

@export var idle_music: AudioStreamWAV
@export var game_over_music: AudioStreamMP3
var bgm_player: AudioStreamPlayer
var music_bus_idx: int
@onready var music_timeout = $MusicTimeOut

const mute_db := -80.0
const default_volume_db := 0.0
const fade_time := 2.0

func _ready() -> void:
	GameManager.gamestate_update.connect(_on_idle)
	music_bus_idx = AudioServer.get_bus_index("Music")
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "Music"
	add_child(bgm_player)

func play_track(track) -> void:
	if track == null:
		push_warning("Audio Manager: Tried to play a null track")
		return
	
	if bgm_player.stream == track and bgm_player.playing:
		return
	
	fade_in_music()
	bgm_player.stream = track
	bgm_player.play()


func _on_idle(state : GameManager.gamestates, cause:String):
	if state == GameManager.gamestates.IDLE:
		play_track(idle_music)
		music_timeout.start()
	else:
		music_timeout.stop()

func _on_music_time_out_timeout() -> void:
	fade_out_music()

func fade_out_music() -> void:
	var tween = create_tween()
	tween.tween_method(set_music_volume, default_volume_db, mute_db, fade_time)

func fade_in_music() -> void:
	set_music_volume(mute_db)
	var tween = create_tween()
	tween.tween_method(set_music_volume, mute_db, default_volume_db, fade_time)

func set_music_volume(volume_db: float) -> void:
	AudioServer.set_bus_volume_db(music_bus_idx, volume_db)
