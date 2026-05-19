#manages player movement & kicking controls. 
extends CharacterBody3D


func _ready() -> void:
	GameManager.gamestate_update.connect(_on_change_state)
	
#
func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	#handle kicking rock
	if GameManager.state == GameManager.gamestates.KICKING:
		pass
		#TODO: update the rock's position

	move_and_slide()

func _on_change_state(state: GameManager.gamestates) -> void:
	match state:
		GameManager.gamestates.IDLE:
			pass
		GameManager.gamestates.CONTRACT:
			pass
		GameManager.gamestates.KICKING:
			_begin_kicking()
		GameManager.gamestates.ROCK_KICKED:
			_kick_rock()
		GameManager.gamestates.SCORING:
			pass

func _begin_kicking() -> void:
	#TODO move the player to the rock
	pass

func _kick_rock() -> void:
	pass
	#TODO handle kicking rock
