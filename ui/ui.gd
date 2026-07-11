# controls everything about the UI, including the contract signing. 
extends Control

# variables
@onready var game_over_text_scroll_speed : float = ((%GameOverText/Bottom.global_position.y + 136) / 50.0)
@onready var game_over_text_reset_pos : Vector2 = %GameOverText.position
@onready var kicks_remaining_bbcode : String = %KicksRemainingLabel.text
@onready var db_loaded : Node = get_node_or_null("/root/MainDatabase")

const OOB_EFFECT_PRE = "[wave amp=100][outline_size=10]"
const OOB_EFFECT_SUF = "[/outline_size][/wave]"

var _start_time := 0.0
var game_over_text_scroll := false
var spinstep = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# connect signals
	GameManager.decrement_kicks_remaining.connect(_on_update_kicks_remaining)
	GameManager.gamestate_update.connect(_on_change_state)
	# need to wait for parent to be ready to avoid race condition
	await $"..".ready
	$"..".rock_followcam_activated.connect(hide_kicking_ui)
	# set initial text
	_on_update_kicks_remaining(GameManager.kicks_remaining) #TODO: more elegant solution.
	
	_clear_ui()
	$IdleMenu.show()
	%IdleAnimationPlayer.play("swing_subtitle")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# scroll the game over text
	if game_over_text_scroll:
		%GameOverText.position.y -= delta * game_over_text_scroll_speed
	
	# Handle the letter spinner
	if %LetterSpinner.visible:
		match spinstep:
			1:
				%Letter1.text = _random_uppercase()
				%Letter2.text = _random_uppercase()
				%Letter3.text = _random_uppercase()
			2:
				%Letter2.text = _random_uppercase()
				%Letter3.text = _random_uppercase()
			3:
				%Letter3.text = _random_uppercase()
		if Input.is_action_just_pressed("confirm") or\
				Input.is_action_just_pressed("kick"):
			spinstep += 1
			if spinstep == 4:
				# checks to see if the db script is loaded
				# and sends the initials to the database to be inserted
				if is_instance_valid(db_loaded):
					db_loaded.set_initials(%Letter1.text, %Letter2.text, %Letter3.text)
				# wait 2 seconds before continuing to kick state
				await get_tree().create_timer(2).timeout
				spinstep = 0
				GameManager.switch_state_to(GameManager.gamestates.KICKING,\
						"contract signed")

# sign player contract
func _input(event: InputEvent) -> void:
	if GameManager.state == GameManager.gamestates.CONTRACT and \
			event.is_action_pressed("confirm"):
		$ContractMenu/ContractContainer.hide()
		%LetterSpinner.show()

# used for letter spinner. Returns a random uppercase character.
func _random_uppercase() -> String:
	return char((randi() % 26) + 65)

# called when signal recieved
func _on_update_kicks_remaining(kick_count: int) -> void:
	var kicks_remaining_str := "KICKS REMAINING: "
	%KicksRemainingLabel.text = (kicks_remaining_bbcode + str(kick_count))
	%KicksRemainingGameplay.text = (kicks_remaining_str + str(kick_count))
	%KicksRemainingFancy.text = (str(kick_count))


# enable and disable UI elements. cause is mostly used for OOB causes
func _on_change_state(state: GameManager.gamestates, cause: String) -> void:
	_clear_ui()
	match state:
		GameManager.gamestates.IDLE:
			$IdleMenu.show()
			%IdleAnimationPlayer.play("swing_subtitle")
		GameManager.gamestates.CONTRACT:
			$ContractMenu.show()
			$ContractMenu/ContractContainer.show()
		GameManager.gamestates.KICKING:
			$KickingMenu.show()
			%KickbarAnimator.play("RESET")
			%KickbarAnimator.play("power_modulate")
		GameManager.gamestates.ROCK_KICKED:
			%KickbarAnimator.pause()
			if %Kickbar.value >= 97.0:
				print("critical kick!")
				%Kickbar.value = 100.0
			$RockKickedMenu.show()
			$KickingMenu.show()
		GameManager.gamestates.SCORING:
			_scoring_sequence()
		GameManager.gamestates.ROCK_OOB:
			$OOBCenterContainer.show()
			%OOBText.text = OOB_EFFECT_PRE + cause + OOB_EFFECT_SUF
			var tween = get_tree().create_tween()
			tween.tween_property(%OOBText, "modulate", Color.WHITE, 1).set_trans(Tween.TRANS_LINEAR)
			await get_tree().create_timer(4).timeout
			tween = get_tree().create_tween()
			tween.tween_property(%OOBText, "modulate", Color.TRANSPARENT, 1).set_trans(Tween.TRANS_LINEAR)
			await get_tree().create_timer(1.5).timeout
			$OOBCenterContainer.hide()

# Scoring sequence function
func _scoring_sequence() -> void:
	
	# Sets the score and then brings up score screen elements, delays for pacing
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
	GameManager.switch_state_to(GameManager.gamestates.IDLE, "scoring sequence finished")


func game_over_text_reset() -> void:
	game_over_text_scroll = false
	%GameOverText.hide()
	%GameOverText.position = game_over_text_reset_pos


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

func hide_kicking_ui():
	$KickingMenu.hide()
