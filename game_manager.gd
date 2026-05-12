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
	,LOSE			#the rock has landed, and the player has 'lost'. 
}

#global variables. These are visible to scripts in other places. (e.g., GameManager.state = GameManager.gamestates.IDLE)
var state := gamestates.IDLE
var kicks_remaining := 1000000




# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	#TODO: load in kicks remaining info from database singleton/node

#restarts the idle timer when input is detected.
func _input(event: InputEvent) -> void:
	%IdleTimer.start()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	
	if Input.is_action_just_pressed("test_kick"):
		$TestSoundPlayer.play()
		_decrement_kicks_remaining()
		
	#come back from idle
	if state == gamestates.IDLE and Input.is_anything_pressed():
		begin_contract_signing()

#TODO implement
func begin_contract_signing() -> void:
	state = gamestates.CONTRACT
	pass

func _decrement_kicks_remaining() -> void:
	kicks_remaining -= 1
	#TODO: write kick(s)/score/timestamp to database
	var ui_ref = $"/root/UI" #TODO: change when we know where UI lives. 
	if ui_ref != null:
		$"../UI".update_kicks_remaining(kicks_remaining)


#handles the cabinet going to IDLE mode.
func _on_idle_timer_timeout() -> void:
	state = gamestates.IDLE
	#TODO: reset other state information
	#TODO: start idle rock-orbiting camera
