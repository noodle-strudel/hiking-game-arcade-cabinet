# Manages player movement & kicking controls. 
extends CharacterBody3D

# Variables
# Player rotation limits in degrees.
@export var rotation_speed: float = 2.0
@export var max_up: float = 45.0
@export var max_down: float = -60.0

# Relative force of kick.
@export var kick_scalar: float = 0.1

@onready var camera: Camera3D = $CameraPivot/PlayerCamera
@onready var legs: Node3D = $Legs
@onready var locked_rotation: bool = false

# Track rotation
var current_y_rotation: float = 0.0
var current_x_rotation: float = 0.0

var rock: Node3D = null
var bar: Node = null

var kick_deviance: float = 0.5

# Constants
## fallback value for kick strength (out of 100). 
const kick_multiplier: float = 100.0
## extra amount added to worst kick possible, to make sure the rock moves a bit
const kick_bias := 0.1
const buddy_rock_path: String = "../Rock"
const kick_bar_path: String = "../UI/KickingMenu/Kickbar"

func _ready() -> void:
	GameManager.gamestate_update.connect(_on_change_state)
	if get_node(buddy_rock_path):
		rock = get_node(buddy_rock_path)
		$RockTeeSpringArm.add_excluded_object(rock)
	elif GameManager.DEBUG:
		print("ERROR: no Rock node sibling to Player.")
		
	if get_node(kick_bar_path):
		bar = get_node(kick_bar_path)
	elif GameManager.DEBUG:
		print("ERROR: no Kickbar node sibling to Player.")

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# If statement making it so player can only rotate in specific states.
	if !locked_rotation and !GameManager.console_open: 
		# Rotate left and right.
		var input_y = Input.get_axis("joystick_right", "joystick_left")
		
		# Update tracking variable.
		current_y_rotation += input_y * rotation_speed * delta 
		
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
			 
	
	# Apply rotation to player.
	rotation.y = current_y_rotation 
	
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
		Input.is_action_just_pressed("kick") and
		!GameManager.console_open
	):
		GameManager.switch_state_to(GameManager.gamestates.ROCK_KICKED, "player just kicked rock")
		var multiplier = kick_multiplier
		if bar:
			multiplier = bar.value
			if GameManager.DEBUG:
				print("fetched value " + str(multiplier) + " from kickbar")
		_kick_rock(multiplier)
	# Fall
	move_and_slide()

func _process(delta: float) -> void:
	# player vision follows the rock.
	if locked_rotation and GameManager.state == GameManager.gamestates.ROCK_KICKED:
		# pull player camera up
		if position.angle_to(rock.position) > current_x_rotation:
			current_x_rotation +=\
				(position.angle_to(rock.position) - current_x_rotation) / 25
				
		# pull player camera down
		elif current_x_rotation > position.angle_to(rock.position):
			current_x_rotation -=\
				(current_x_rotation - position.angle_to(rock.position)) / 15
		
		# hold player camera on rock
		else:
			current_x_rotation = position.angle_to(rock.position)

func _on_change_state(state: GameManager.gamestates, _cause: String) -> void:
	$RockTeeSpringArm/TeePos.remote_path = ""
	locked_rotation = true
	match state:
		GameManager.gamestates.KICKING: 
			locked_rotation = false
		GameManager.gamestates.ROCK_KICKED:
			await get_tree().process_frame
			if GameManager.critical_kick:
				$CameraPivot/PlayerCamera.apply_shake(1)
		GameManager.gamestates.ROCK_OOB:
			await get_tree().create_timer(0.1).timeout
			if rock:
				rock.angular_velocity = Vector3(0.0, 0.0, 0.0)
				rock.linear_velocity = Vector3(0.0, 0.0, 0.0)
		GameManager.gamestates.MOVE_TO_ROCK:
			look_at(rock.global_position)
			_go_to_rock()

# Function that makes the player move to the rock after scoring
func _go_to_rock() -> void:
	var tween = create_tween()
	if rock:
		# Player will walk to the side of the rock closest to the player
		var goal_posiiton = rock.global_position +\
			(global_position.direction_to(rock.global_position) * Vector3.FORWARD)
		
		legs.play_run()
		
		# Tween that moves the player to the rock 1 away in Z direction.
		tween.tween_property(self,
			"global_position",
			goal_posiiton,
			10
		)
		
		# Lambda function to stop the walk animation and switch to the idle state.
		tween.tween_callback(func():
			legs.stop_run()
			GameManager.switch_state_to(GameManager.gamestates.IDLE, "player got to rock")
		)

# Randomizes the dimensions of a Vector3 (for kick impulse).
func _vec_noise(input: Vector3, amt: float) -> Vector3:
	return Vector3(
		input.x + randfn(0, amt), 
		input.y + randfn(0, amt), 
		input.z + randfn(0, amt)
	)

# Handles kicking the rock when the state changes. 
func _kick_rock(multiplier := kick_multiplier) -> void:
	if rock:
		var direction_to_rock: Vector3 = rock.position - self.position
		
		# Fixes inconsistent rock force due to rock distance
		direction_to_rock = direction_to_rock.normalized() 
		var pretotal_kick = ((multiplier * (1 - kick_bias)) + (kick_multiplier * kick_bias))
		var total_kick: float = kick_scalar * pretotal_kick
		
		var impulse_vector: Vector3 = (direction_to_rock * total_kick) + Vector3(0.0, total_kick / 2, 0.0)
		
		impulse_vector = _vec_noise(impulse_vector, kick_deviance)
		rock.apply_impulse(impulse_vector)
		
		# Get kick strength to use for calculating the kick score.
		GameManager.current_kick_strength = impulse_vector.length()
		
		# Play kick animation
		legs.play_kick()
