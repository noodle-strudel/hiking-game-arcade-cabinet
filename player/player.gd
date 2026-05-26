# Manages player movement & kicking controls. 
extends CharacterBody3D

# Player rotation limits in degrees.
@export var rotation_speed: float = 2.0
@export var max_left: float = 45.0
@export var max_right: float = -45.0
@export var max_up: float = 45.0
@export var max_down: float = -60.0

@onready var camera: Camera3D = $CameraPivot/PlayerCamera

# Track rotation
var current_y_rotation: float = 0.0
var current_x_rotation: float = 0.0

# variables
const buddy_rock_path = "../Rock"
var rock = null
var bar = null
var kick_scalar = 5.0 #relative force of kick.
var kick_deviance = 0.5

func _ready() -> void:
	GameManager.gamestate_update.connect(_on_change_state)
	if get_node(buddy_rock_path):
		rock = get_node(buddy_rock_path)
		$RockTeeSpringArm.add_excluded_object(rock) #
	else:
		print("ERROR: no Rock node sibling to Player.")
		
	if get_node("../UI/KickingMenu/PowerBar/KickbarInd"):
		bar = get_node("../UI/KickingMenu/PowerBar/KickbarInd")
	else:
		print("ERROR: no Kickbar node sibling to Player.")

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Rotate left and right.
	var input_y = Input.get_axis("joystick_right", "joystick_left")
	current_y_rotation += input_y * rotation_speed * delta # Update tracking variable.
	rotation.y = current_y_rotation # Apply rotation to player.
	
	# Rotate up and down.
	var input_x = Input.get_axis("joystick_down", "joystick_up")
	current_x_rotation += input_x * rotation_speed * delta # Update tracking variable.
	current_x_rotation = clamp(current_x_rotation, deg_to_rad(max_down), deg_to_rad(max_up)) # Apply clamps.
	camera.rotation.x = current_x_rotation # Apply rotation to camera.
	
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
			if bar:
				kick_scalar = abs(bar.position.x / 15)
			_kick_rock()
			
			# reset the max rotation of the player based on the current y pos
			max_left = (rad_to_deg(current_y_rotation) + 45.0)
			max_right = (rad_to_deg(current_y_rotation) - 45.0)


#moves the player to the rock when the state changes. 
func _begin_kicking() -> void:
	if rock:
		self.position = rock.position + Vector3(0.0, 0.0, 1.0)

# randomizes the dimensions of a Vector3 (for kick impulse)
func _vec_noise(input: Vector3, amt: float) -> Vector3:
	return Vector3(input.x + randfn(0, amt),\
			input.y + randfn(0, amt),\
			input.z + randfn(0, amt))

#handles kicking the rock when the state changes. 
func _kick_rock() -> void:
	if rock:
		var direction_to_rock := Vector3(rock.position - self.position)
		direction_to_rock = direction_to_rock.normalized() #fixes issues
		var impulse_vector = direction_to_rock * kick_scalar + Vector3(0.0, kick_scalar, 0.0)
		impulse_vector = _vec_noise(impulse_vector, kick_deviance)
		rock.apply_impulse(impulse_vector)
		#report kick to game manager
		GameManager.report_kick(impulse_vector.length())
