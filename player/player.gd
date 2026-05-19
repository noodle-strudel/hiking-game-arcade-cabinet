# Manages player movement & kicking controls. 
extends CharacterBody3D

# Player rotation limits in degrees.
@export var rotation_speed: float = 2.0
@export var max_left: float = 45.0
@export var max_right: float = -45.0
@export var max_up: float = 45.0
@export var max_down: float = -45.0

@onready var camera: Camera3D = $CameraPivot/PlayerCamera

# Track rotation
var current_y_rotation: float = 0.0
var current_x_rotation: float = 0.0

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	move_and_slide()
	
	# Rotate left and right.
	var input_y = Input.get_axis("joystick_right", "joystick_left")
	current_y_rotation += input_y * rotation_speed * delta # Update tracking variable.
	current_y_rotation = clamp(current_y_rotation, deg_to_rad(max_right), deg_to_rad(max_left)) # Apply clamps.
	rotation.y = current_y_rotation # Apply rotation to player.
	
	# Rotate up and down.
	var input_x = Input.get_axis("joystick_down", "joystick_up")
	current_x_rotation += input_x * rotation_speed * delta # Update tracking variable.
	current_x_rotation = clamp(current_x_rotation, deg_to_rad(max_down), deg_to_rad(max_up)) # Apply clamps.
	camera.rotation.x = current_x_rotation # Apply rotation to camera.
			
	
	
