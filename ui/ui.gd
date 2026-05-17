#controls everything about the UI, including the contract signing. 
extends Control

#variables
var _start_time := 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#connect signals
	GameManager.decrement_kicks_remaining.connect(_on_update_kicks_remaining)
	GameManager.cabinet_is_idle.connect(_on_cabinet_idle)
	#set initial text
	_on_update_kicks_remaining(GameManager.kicks_remaining) #TODO: more elegant solution.
	
	#get start time
	_start_time = Time.get_unix_time_from_system()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#rotate the subtitle
	if $IdleMenu.visible:
		var time_delta = Time.get_unix_time_from_system() - _start_time
		var spin = 0.01 * sin(time_delta * 4)
		$IdleMenu/SubtitlePivot.rotation -= spin


#called when signal recieved
func _on_update_kicks_remaining(kick_count: int) -> void:
	%KicksRemainingLabel.text = ("KICKS REMAINING: " + str(kick_count))
	
func _on_cabinet_idle():
	pass
