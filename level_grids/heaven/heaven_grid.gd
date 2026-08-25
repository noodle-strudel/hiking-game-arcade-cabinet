extends Grid
class_name HeavenGrid


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	GameManager.gamestate_update.connect(_on_change_state)

func _on_change_state(state: GameManager.gamestates, _cause: String) -> void:
	if state == GameManager.gamestates.KICKING:
		$OOBBarrier.set_deferred("monitoring", true)
		$LakeBarrier.set_deferred("monitoring", true)

func _on_oob_barrier_body_entered(body: Node3D) -> void:
	if body.name == "Rock":
		GameManager.switch_state_to(GameManager.gamestates.ROCK_OOB, "The rock fell through the ground...")
	
	# failsafe to just reload the entire game
	if body.name == "Player":
		get_tree().reload_current_scene()
	$OOBBarrier.set_deferred("monitoring", false)


func _on_lake_barrier_body_entered(body: Node3D) -> void:
	if body.name == "Rock":
		$LakeSplooshSFX.play()
		$OOBBarrier.set_deferred("monitoring", false)
		$LakeBarrier.set_deferred("monitoring", false)
		
		# ensure the rock doesn't trigger other area2ds during this.
		# NOTE: For some reason making the barriers not monitoring only works
		# at the top which is why i had to set the rock's stuff instead
		var rock_col_layer_reset = body.collision_layer
		var rock_col_mask_reset = body.collision_mask
		body.collision_layer = 0
		body.collision_mask = 0
		GameManager.switch_state_to(GameManager.gamestates.ROCK_OOB, "The rock fell in the heavenly lake...")
		await get_tree().create_timer(2).timeout
	
		# reset rock's collisions so it can interact with the world again
		body.collision_mask = rock_col_mask_reset
		body.collision_layer = rock_col_layer_reset
		
