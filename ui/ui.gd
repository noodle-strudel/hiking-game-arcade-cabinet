#controls everything about the UI, including the contract signing. 
extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func update_kicks_remaining(kick_count: int) -> void:
	$KicksRemainingLabel.text = ("Kicks remaining: " + str(kick_count))
