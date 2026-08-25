extends Grid


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	GameManager.gamestate_update.connect(_on_change_state)

func _on_change_state(state: GameManager.gamestates, _cause: String) -> void:
	if state == GameManager.gamestates.KICKING:
		$OOBBarrier.set_deferred("monitoring", true)

func _on_oob_barrier_body_entered(body: Node3D) -> void:
	if body.name == "Rock":
		GameManager.switch_state_to(GameManager.gamestates.ROCK_OOB, "The rock fell through the ground...")
	
	# failsafe to just reload the entire game
	if body.name == "Player":
		get_tree().reload_current_scene()
	$OOBBarrier.set_deferred("monitoring", false)
