#manages player movement & kicking controls. 
extends CharacterBody3D

#variables
const buddy_rock_path = "../Rock"
var rock = null
var kick_scalar = 5.0 #relative force of kick.

func _ready() -> void:
	GameManager.gamestate_update.connect(_on_change_state)
	if get_node(buddy_rock_path):
		rock = get_node(buddy_rock_path)
		$RockTeeSpringArm.add_excluded_object(rock) #
	else:
		print("ERROR: no Rock node sibling to Player.")

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	#handle keeping the rock in front of the player when ready to kick.
	#if the rock's height needs to be adjusted, change the Margin value in $RockTeeSpringArm's inspector.
	if GameManager.state == GameManager.gamestates.KICKING:
		if rock:
			rock.linear_velocity = Vector3(0.0,0.0,0.0) #to counteract accumulating gravity
			rock.set_position($RockTeeSpringArm/TeePos.get_global_position())

	#fall.
	move_and_slide()

func _on_change_state(state: GameManager.gamestates) -> void:
	$RockTeeSpringArm/TeePos.remote_path = ""
	match state:
		GameManager.gamestates.KICKING:
			_begin_kicking()
		GameManager.gamestates.ROCK_KICKED:
			_kick_rock()


#moves the player to the rock when the state changes. 
func _begin_kicking() -> void:
	if rock:
		self.position = rock.position + Vector3(0.0, 0.0, 1.0)

#handles kicking the rock when the state changes. 
func _kick_rock() -> void:
	if rock:
		var direction_to_rock := Vector3(rock.position - self.position)
		rock.apply_impulse(direction_to_rock*kick_scalar + Vector3(0.0, kick_scalar, 0.0))
