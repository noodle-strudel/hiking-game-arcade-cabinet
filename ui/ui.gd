# controls everything about the UI, including the contract signing. 
extends Control

# variables
var _start_time := 0.0
var game_over_text_scroll := false
@onready var game_over_text_scroll_speed : float = ((%GameOverText/Bottom.global_position.y + 136) / 50.0)
@onready var game_over_text_reset_pos : Vector2 = %GameOverText.position
var spinstep = 0

# Called when the node enters the scene tree for the first time.yyyyyyyy
func _ready() -> void:
	# connect signals
	GameManager.decrement_kicks_remaining.connect(_on_update_kicks_remaining)
	GameManager.gamestate_update.connect(_on_change_state)
	# set initial text
	_on_update_kicks_remaining(GameManager.kicks_remaining) #TODO: more elegant solution.
	
	# get start time
	_start_time = Time.get_unix_time_from_system()
	
	_clear_ui()
	$IdleMenu.show()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# rotate the subtitle
	if $IdleMenu.visible:
		var time_delta = Time.get_unix_time_from_system() - _start_time
		var spin = 0.01 * sin(time_delta * 4)
		$IdleMenu/SubtitlePivot.rotation -= spin
	# scroll the game over text
	if game_over_text_scroll:
		%GameOverText.position.y -= delta * game_over_text_scroll_speed
	# hide the contract after it is signed and go to the letter spinner
	if GameManager.state == GameManager.gamestates.CONTRACT and\
			Input.is_action_just_pressed("confirm"):
		$ContractMenu/ContractContainer.hide()
		%LetterSpinner.show()
	# Handle the letter spinner
	if %LetterSpinner.visible:
		if(spinstep < 2):
			%Letter1.text = char((randi() % 26) + 65)
		if(spinstep < 3):
			%Letter2.text = char((randi() % 26) + 65)
		if(spinstep < 4):
			%Letter3.text = char((randi() % 26) + 65)
		if Input.is_action_just_pressed("confirm") or\
				Input.is_action_just_pressed("kick"):
			spinstep += 1
			if spinstep == 4:
				# wait 2 seconds before continuing to kick state
				await get_tree().create_timer(2).timeout
				spinstep = 0
				GameManager.switch_state_to(GameManager.gamestates.KICKING,\
						"contract signed")


# called when signal recieved
func _on_update_kicks_remaining(kick_count: int) -> void:
	%KicksRemainingLabel.text = ("KICKS REMAINING: " + str(kick_count))
	%KicksRemainingGameplay.text = ("KICKS REMAINING: " + str(kick_count))
	%KicksRemainingFancy.text = (str(kick_count))


# enable and disable UI elements. cause is mostly used for OOB causes
func _on_change_state(state: GameManager.gamestates, cause: String) -> void:
	_clear_ui()
	match state:
		GameManager.gamestates.IDLE:
			$IdleMenu.show()
		GameManager.gamestates.CONTRACT:
			$ContractMenu.show()
			$ContractMenu/ContractContainer.show()
		GameManager.gamestates.KICKING:
			$KickingMenu.show()
		GameManager.gamestates.ROCK_KICKED:
			$RockKickedMenu.show()
		GameManager.gamestates.SCORING:
			_scoring_sequence()
		GameManager.gamestates.ROCK_OOB:
			$OOBText.text = cause
			$OOBText.show()
			await get_tree().create_timer(2).timeout
			$OOBText.hide()
			GameManager.switch_state_to(GameManager.gamestates.KICKING)


func _scoring_sequence() -> void:
	$ScoreMenu/ScoreElem/RoundScore.text = (str(GameManager.last_score))
	$ScoreMenu.show()
	await get_tree().create_timer(1).timeout
	%ScoreElem.show()
	await get_tree().create_timer(1).timeout
	%KicksRemainingElem.show()
	await get_tree().create_timer(1).timeout
	%KicksRemainingFancy.show()
	
	# long, drawn out ending animation #TODO make fancier.
	await get_tree().create_timer(1).timeout
	%GameOverText.show()
	game_over_text_scroll = true
	AudioManager.play_track(AudioManager.game_over_music)
	await get_tree().create_timer(50).timeout
	AudioManager.fade_out_music()


func game_over_text_reset() -> void:
	game_over_text_scroll = false
	%GameOverText.hide()
	%GameOverText.position = game_over_text_reset_pos
	$ScoreMenu/EpicMusicPlayer.stop()


func _clear_ui() -> void:
	# hide each menu
	var menus = get_children()
	for menu in menus:
		menu.hide()
	# reset for scoring sequence
	%ScoreElem.hide()
	%KicksRemainingElem.hide()
	%KicksRemainingFancy.hide()
	game_over_text_reset()
	# reset for contract sequence 
	%Contract.show()
	%LetterSpinner.hide()


func _on_epic_music_player_finished() -> void:
	GameManager.switch_state_to(GameManager.gamestates.IDLE, "scoring sequence finished")
