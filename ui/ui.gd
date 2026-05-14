#controls everything about the UI, including the contract signing. 
extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#connect signals
	GameManager.decrement_kicks_remaining.connect(_on_update_kicks_remaining)
	#set initial text
	_on_update_kicks_remaining(GameManager.kicks_remaining) #TODO: more elegant solution.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

#called when signal recieved
func _on_update_kicks_remaining(kick_count: int) -> void:
	$KicksRemainingLabel.text = ("Kicks remaining: " + str(kick_count))
