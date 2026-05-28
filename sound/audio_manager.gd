extends Node

@export var idle_music: AudioStreamWAV
@export var game_over_music: AudioStreamMP3
@onready var bgm_player: AudioStreamPlayer = $MusicPlayer
@onready var music_bus_idx: int = AudioServer.get_bus_index("Music")

const mute_db := -80.0
const default_volume_db := 0.0
const fade_time := 3.0

func _ready() -> void:
	GameManager.gamestate_update.connect(_on_idle)

#plays the specified track passed in when called with AudioManager.play_track()
func play_track(track) -> void:
	#Makes sure the track is not null or already playing before fading in and playing it
	if track == null:
		push_warning("Audio Manager: Tried to play a null track")
		return
	
	if bgm_player.stream == track and bgm_player.playing:
		return
	
	fade_in_music()
	bgm_player.stream = track
	bgm_player.play()


func _on_idle(state : GameManager.gamestates, _cause:String):
	#when the state changes to idle it plays the idle music and starts the time out timer
	if state == GameManager.gamestates.IDLE:
		play_track(idle_music)
		%MusicTimeOut.start()
	else:#fades out the music if the scene is switched to a different scene
		%MusicTimeOut.timeout.emit()

func _on_music_time_out_timeout() -> void:
	fade_out_music()

func fade_out_music() -> void:
	#tween allows for fading the sound in and out calling the set volume method
	#with over the fade time changing from the second value to the 3rd
	var tween = create_tween()
	tween.tween_method(set_music_volume, default_volume_db, mute_db, fade_time)
	#without waiting it would stop without fading out
	await get_tree().create_timer(fade_time).timeout
	AudioManager.bgm_player.stop()

func fade_in_music() -> void:
	#it also allows for fading in the sound doing the same process just swapping
	#the start and end variables
	set_music_volume(mute_db)
	var tween = create_tween()
	tween.tween_method(set_music_volume, mute_db, default_volume_db, fade_time)

func set_music_volume(volume_db: float) -> void:
	#simple function to allow seting the volume on the music bus
	AudioServer.set_bus_volume_db(music_bus_idx, volume_db)
