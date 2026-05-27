#This globally loaded scene manages the state of the game. 
#To access this node's globally visible variables/functions, do this:
# var number = GameManager.kicks_remaining
# GameManager.lose()
#contact Melody if you have questions
extends Node

enum gamestates {
	IDLE 			#The cabinet is idle (no input recieved for a while). 
	,CONTRACT		#The player is signing the 'contract'.
	,KICKING		#the player is aiming their kick
	,ROCK_KICKED	#the rock has been kicked, and the camera follows it. 
	,SCORING		#the rock has landed, and the player has 'lost'. Show scoring. 
}

#signals
#DOCUMENTATION FROM MELODY:
# if you want your script to listen to any of this script's signals, do this:
# 1. write a line like this in the script's _ready() function:
#    GameManager.signalname.connect(_signal_handling_function_name)
# 2. then, implement the function that handles receiving that signal. 
# Check res://ui/ui.gd for an example, including arguements. 
signal decrement_kicks_remaining(new_kick_count) #a kick just happened. 
#signal cabinet_is_idle #no input detected for a while. #depreciated
signal gamestate_update(state) #the state has changed. Used for idle as well

#global variables. These are visible to scripts in other places.
# (e.g., GameManager.state = GameManager.gamestates.IDLE)
var distance_kicked := 0
var state := gamestates.IDLE
var kicks_remaining := 1000000
var last_kick_strength := 0.0
var last_score := 100

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#TODO: load in kicks remaining info from database singleton/node
	pass
	#
	

#restarts the idle timer when input is detected.
func _input(_event: InputEvent) -> void:
	%IdleTimer.start()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("test_kick"):
		$TestSoundPlayer.play()
		_decrement_kicks_remaining()
	
	#come back from idle
	if state == gamestates.IDLE and Input.is_anything_pressed():
		begin_contract_signing()
	
	
	#TEST CODE FOR STATE SWITCHING.
	_test_state_handler() #Allows keys 1-5 to force update the gamestate. 

#TODO implement
func begin_contract_signing() -> void:
	_switch_state(gamestates.CONTRACT)
	#


func _decrement_kicks_remaining() -> void:
	kicks_remaining -= 1
	decrement_kicks_remaining.emit(kicks_remaining)

#handles the cabinet going to IDLE mode.
func _on_idle_timer_timeout() -> void:
	_switch_state(gamestates.IDLE)
	#TODO: reset other state information
	#TODO: start idle rock-orbiting camera

#switches the current state and emits an update signal. 
func _switch_state(target_state: GameManager.gamestates):
	if state == gamestates.ROCK_KICKED:
		_decrement_kicks_remaining()
	state = target_state
	gamestate_update.emit(state)

func report_distance(kick_distance: float) -> void:
	distance_kicked = kick_distance
	report_score()
	
# Get kick strength.
func report_kick(kick_strength: float) -> void:
	last_kick_strength = kick_strength
	
# Get score for scoring gamestate.
func report_score():
	last_score = int((last_kick_strength + distance_kicked) * 20)
	
#TEST
func _test_state_handler() -> void:
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
		$TestSoundPlayer.play()
		_switch_state(gamestates.ROCK_KICKED)	
	if Input.is_action_just_pressed("test_set_state_scoring"):
		$TestSoundPlayer.play()
		_switch_state(gamestates.SCORING)	
