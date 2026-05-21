extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.gamestate_update.connect(_change_camera)
	pass # Replace with function body.

# Camera changes based on gamestate.
func _change_camera(state: GameManager.gamestates) -> void:
	match state:
		GameManager.gamestates.IDLE:
			$Rock/RockCameraPivot/RockCameraArm/RockCamera.make_current()
		GameManager.gamestates.CONTRACT:
			$Player/CameraPivot/PlayerCamera.make_current()
		GameManager.gamestates.KICKING:
			$Player/CameraPivot/PlayerCamera.make_current()
		GameManager.gamestates.ROCK_KICKED:
			$Rock/RockCameraPivot/RockCameraArm/RockCamera.make_current()
		GameManager.gamestates.SCORING:
			$Rock/RockCameraPivot/RockCameraArm/RockCamera.make_current()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
