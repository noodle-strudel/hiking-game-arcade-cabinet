extends Node

@export var idle_music: AudioStreamWAV
@export var game_over_music: AudioStreamWAV
@export var background_music: AudioStreamMP3
@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var music_bus_idx: int = AudioServer.get_bus_index("Music")

var bgm_position := 0.0

const mute_db := -30.0
const default_volume_db := -5.0
const fade_time := 2.0

func _ready() -> void:
	GameManager.gamestate_update.connect(_on_state_change)

#plays the specified track passed in when called with AudioManager.play_track()
func play_track(track) -> void:
	#Makes sure the track is not null or already playing before fading in and playing it
	if track == null:
		push_warning("Audio Manager: Tried to play a null track")
		return
	
	if music_player.stream == track and music_player.playing:
		return
	
	music_player.stream = track
	#since the background music pauses and resumes it has to play from the
	#position in the track from when it last played starts at 0 by default
	if music_player.stream == background_music:
		music_player.play(bgm_position)
	else:
		music_player.play()
	fade_in_music()

func _on_state_change(state : GameManager.gamestates, _cause:String):
	#if the background music is playing this stores how far into the
	#song it is before handling state switch.
	if music_player.stream == background_music:
		bgm_position = music_player.get_playback_position()
	match state:
		#in idle the game fades out whatever is playing before playing idle music
		#and starting the timeout timer
		GameManager.gamestates.IDLE:
			fade_out_music()
			await get_tree().create_timer(fade_time).timeout
			play_track(idle_music)
			%MusicTimeOut.start()
		#in the contract kicking and oob states this makes sure to fade out
		#whatever music is playing if it isn't already the background music
		GameManager.gamestates.CONTRACT, GameManager.gamestates.KICKING, GameManager.gamestates.ROCK_OOB:
			if music_player.stream != background_music:
				%MusicTimeOut.stop()
				%MusicTimeOut.timeout.emit()
				await get_tree().create_timer(fade_time).timeout
			play_track(background_music)
		#in any other cases this just makes sure to stop the music
		#that is currently playing
		_:
			%MusicTimeOut.stop()
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
	music_player.stop()

func fade_in_music() -> void:
	#it also allows for fading in the sound doing the same process just swapping
	#the start and end variables
	set_music_volume(mute_db)
	var tween = create_tween()
	tween.tween_method(set_music_volume, mute_db, default_volume_db, fade_time)

func set_music_volume(volume_db: float) -> void:
	#simple function to allow seting the volume on the music bus
	AudioServer.set_bus_volume_db(music_bus_idx, volume_db)
