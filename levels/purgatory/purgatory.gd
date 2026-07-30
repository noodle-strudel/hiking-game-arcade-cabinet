extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	open_gates()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func open_gates() -> void:
	$LevelSegments/HeavenStairsGrid.open_gates()
