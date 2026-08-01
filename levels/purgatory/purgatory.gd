extends Node3D

signal stairs_camera_finished

@onready var stairs_camera := $StairsCamera

func stairs_camera_dolly() -> void:
	%StairsCameraAnimator.play("ascend_stairs")
	await %StairsCameraAnimator.animation_finished
	stairs_camera_finished.emit()

func open_gates() -> void:
	$LevelSegments/HeavenStairsGrid.open_gates()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
