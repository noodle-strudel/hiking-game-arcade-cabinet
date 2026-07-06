# Manages player movement & kicking controls. 
extends CharacterBody3D

# Variables
# Player rotation limits in degrees.
@export var rotation_speed: float = 2.0
@export var max_up: float = 45.0
@export var max_down: float = -60.0

# Relative force of kick.
@export var kick_scalar: float = 10.0 

@onready var camera: Camera3D = $CameraPivot/PlayerCamera
@onready var legs: Node3D = $Legs

# Track rotation
var current_y_rotation: float = 0.0
var current_x_rotation: float = 0.0

var rock: Node = null
var bar: Node = null
var kick_bar_multiplier: float = 0.0
var kick_deviance: float = 0.5

# Constants
const buddy_rock_path: String = "../Rock"
const kick_bar_path: String = "../UI/KickingMenu/PowerBar/KickbarInd"

func _ready() -> void:
	GameManager.gamestate_update.connect(_on_change_state)
	if get_node(buddy_rock_path):
		rock = get_node(buddy_rock_path)
		$RockTeeSpringArm.add_excluded_object(rock)
	else:
		print("ERROR: no Rock node sibling to Player.")
		
	if get_node(kick_bar_path):
		bar = get_node(kick_bar_path)
	else:
		print("ERROR: no Kickbar node sibling to Player.")

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Rotate left and right.
	var input_y = Input.get_axis("joystick_right", "joystick_left")
	
	# Update tracking variable.
	current_y_rotation += input_y * rotation_speed * delta 
	
	# Apply rotation to player.
	rotation.y = current_y_rotation 
	
	# Rotate up and down.
	var input_x = Input.get_axis("joystick_down", "joystick_up")
	
	# Update tracking variable.
	current_x_rotation += input_x * rotation_speed * delta 
	
	# Apply clamps.
	current_x_rotation = clamp(
		current_x_rotation, 
		deg_to_rad(max_down), 
		deg_to_rad(max_up)
	)
		
	# Apply rotation to camera.
	camera.rotation.x = current_x_rotation 
	
	# Handle keeping the rock in front of the player when ready to kick.
	# If the rock's height needs to be adjusted, change the Margin value
	# in $RockTeeSpringArm's inspector.
	if GameManager.state == GameManager.gamestates.KICKING:
		if rock:
			# Counteract accumulating gravity.
			rock.linear_velocity = Vector3(0.0, 0.0, 0.0)
			rock.angular_velocity = Vector3(0.0, 0.0, 0.0)
			rock.set_position($RockTeeSpringArm/TeePos.get_global_position())
	
	# Handle kicking the rock.
	if (
		GameManager.state == GameManager.gamestates.KICKING and
		Input.is_action_just_pressed("kick")
	):
		GameManager.switch_state_to(GameManager.gamestates.ROCK_KICKED)
		if bar:
			kick_bar_multiplier = abs(bar.position.x / 80)
		_kick_rock()
		
	# Fall
	move_and_slide()

func _on_change_state(state: GameManager.gamestates, _cause: String) -> void:
	$RockTeeSpringArm/TeePos.remote_path = ""
	match state:
		GameManager.gamestates.KICKING:
			_begin_kicking()
		GameManager.gamestates.ROCK_OOB:
			await get_tree().create_timer(0.1).timeout
			if rock:
				rock.angular_velocity = Vector3(0.0, 0.0, 0.0)
				rock.linear_velocity = Vector3(0.0, 0.0, 0.0)

# Moves the player to the rock when the state changes. 
func _begin_kicking() -> void:
	if rock:
		self.position = rock.position + Vector3(0.0, 0.0, 1.0)

# Randomizes the dimensions of a Vector3 (for kick impulse).
func _vec_noise(input: Vector3, amt: float) -> Vector3:
	return Vector3(
		input.x + randfn(0, amt), 
		input.y + randfn(0, amt), 
		input.z + randfn(0, amt)
	)

# Handles kicking the rock when the state changes. 
func _kick_rock() -> void:
	if rock:
		var direction_to_rock: Vector3 = rock.position - self.position
		
		# Fixes inconsistent rock force due to rock distance
		direction_to_rock = direction_to_rock.normalized() 
		
		var total_kick: float = kick_scalar * kick_bar_multiplier
		var impulse_vector: Vector3 = (direction_to_rock * total_kick) + Vector3(0.0, total_kick / 2, 0.0)
		
		impulse_vector = _vec_noise(impulse_vector, kick_deviance)
		rock.apply_impulse(impulse_vector)
		
		# Get kick strength to use for calculating the kick score.
		GameManager.current_kick_strength = impulse_vector.length()
		
		# Play kick animation
		legs.play_kick()
