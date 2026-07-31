# This globally loaded scene manages the state of the game. 
# To access this node's globally visible variables/functions, do this:
# 	var number = GameManager.kicks_remaining
# 	GameManager.lose()
extends Node

## Emitted when a kick occurs. Use new_kick_count to update counters & the like. 
signal decrement_kicks_remaining(new_kick_count)
## Emitted when the game state has changed. Use (state, cause) as needed. 
signal gamestate_update(state, cause) # the state has changed. Used for idle as well

@onready var state := gamestates.IDLE
var kicks_remaining := 1000000
var current_kick_strength := 0.0
var last_score := 100
var DEBUG := OS.is_debug_build()
var console_open := false
# Number of kicks, at or below which the player will play in purgatory.
const purgatory_kick_count = 10000
const heaven_kick_count = 8000

## States of the game.
## Can be IDLE, CONTRACT, KICKING, ROCK_KICKED, POSTKICK_EVENT, SCORING, or ROCK_OOB
enum gamestates {
	## The cabinet is idle (no input received for a while). 
	IDLE,
	## The player is signing the 'contract'.
	CONTRACT,
	## The player is aiming their kick.
	KICKING,
	## The rock has been kicked, and the camera follows it.
	ROCK_KICKED,
	## Used during some events, as a buffer between ROCK_KICKED and SCORING
	POSTKICK_EVENT,
	## The rock has landed, and the player has 'lost'. Show scoring.
	SCORING,
	## The rock has gone out of bounds or in a lake
	ROCK_OOB,
	## Used when the player is moving to the rock.
	MOVE_TO_ROCK,
	## Kicks remaining is 0 and the rock is a perfect sphere.
	ROCK_PERFECTED,
}


# Public function to allow the state to be switched from any script.
## Switches the game state to target_state
func switch_state_to(target_state: GameManager.gamestates, cause: String = "") -> void:
		_switch_state(target_state, cause)
		if DEBUG:
			print("DEBUG: state switch requested with cause \"" + cause + "\"")

## Updates last_score to the newest score calculation. 
func report_score(kick_strength: float, kick_distance: float) -> void:
	last_score = int((kick_strength + kick_distance) * 20)
	if DEBUG:
		print(
			"Kick Strength: ", kick_strength,
			" | Distance Kicked: ", kick_distance,
			" | Score: ", last_score
		)
	
## Decrements the kicks remaining and emits a signal.
func _decrement_kicks_remaining() -> void:
	kicks_remaining -= 1
	decrement_kicks_remaining.emit(kicks_remaining)


## Signal handler for the cabinet going to IDLE mode.
func _on_idle_timer_timeout() -> void:
	if state != gamestates.IDLE:
		_switch_state(gamestates.IDLE)


## switches the current state and emits an update signal. 
func _switch_state(target_state: GameManager.gamestates, cause: String = "") -> void:
	if state == gamestates.ROCK_KICKED:
		_decrement_kicks_remaining()
	state = target_state
	gamestate_update.emit(state, cause)


## Signal handler for when the gamestate changes.
func _on_change_state(_state: gamestates, _cause: String) -> void:
	match _state:
		gamestates.MOVE_TO_ROCK:
			%IdleTimer.start()


## Enables use of number keys 1-5 to set the game state. 
func _test_state_handler() -> void:
	if !console_open:
		if Input.is_action_just_pressed("test_set_state_idle"):
			$TestSoundPlayer.play()
			_switch_state(gamestates.IDLE)	
		if Input.is_action_just_pressed("test_set_state_contract"):
			$TestSoundPlayer.play()
			_switch_state(gamestates.CONTRACT)	
		if Input.is_action_just_pressed("test_set_state_kicking"):
			$TestSoundPlayer.play()
			_switch_state(gamestates.KICKING)	
		if Input.is_action_just_pressed("test_set_state_rock_kicked"):
			# $TestSoundPlayer.play()
			_switch_state(gamestates.ROCK_KICKED)	
		if Input.is_action_just_pressed("test_set_state_scoring"):
			$TestSoundPlayer.play()
			_switch_state(gamestates.SCORING)	


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	gamestate_update.connect(_on_change_state)
	Console.console_opened.connect(_console_open)
	Console.console_closed.connect(_console_closed)

# Sets the console open value to true to stop console input being used in the game
func _console_open() -> void:
	console_open = true

# Sets the console open value to false allowing game input to work again
func _console_closed() -> void:
	console_open = false

# Restarts the idle timer when input is detected.
func _input(_event: InputEvent) -> void:
	if !console_open:
		%IdleTimer.start()
		if (
			state == gamestates.IDLE and 
			(Input.is_action_just_pressed("kick") or 
			Input.is_action_just_pressed("confirm"))
		):
			_switch_state(gamestates.CONTRACT)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("test_kick") and !console_open:
		# $TestSoundPlayer.play()
		_decrement_kicks_remaining()
	
	#TEST CODE FOR STATE SWITCHING.
	_test_state_handler() # Allows keys 1-5 to force update the gamestate. 
