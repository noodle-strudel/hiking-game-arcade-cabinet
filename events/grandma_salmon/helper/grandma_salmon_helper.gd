extends Node3D
class_name GrandmaSalmonHelper

"""HOW TO USE
1. Instantiate
2. Let it snatch_object(obj.get_path())
3. Call move_rock(from_pos, to_pos)
4. Once the movement is done, get_snatcher_pos()
   of the snatcher, assign to obj, and release_object()
"""

#NOTE: You could probably release the object before it completes
#      if you wanna do something fancy

signal on_movement_finished

# gives a jumping look during lerp
@export var movement_curve: Curve
@export var speed: float = 0.4
@export var heaven_curve: Curve

# multiplier to the y axis
const Y_MULTIPLIER = 2

# determines if grandma salmon is moving or not
var _moving: bool = false

# interpolation step from 0.0 to 1.0 (start to finish)
var _t: float = 0.0

# starting position
var _from: Vector3

# ending position
var _to: Vector3

# type of y-movement
var _step: int

# wrapper function of sorts to enable salmon grandma movement
func move_obj(from: Vector3, to: Vector3, step: int = 0) -> void:
	_t = 0.0
	_from = from
	_to = to
	_step = step
	_moving = true

func snatch_object(obj: NodePath) -> void:
	$RockSnatch.set_remote_node(obj)

func release_object() -> void:
	if $RockSnatch.remote_path:
		$RockSnatch.set_remote_node("")

func play_talk_anim() -> void:
	$SubViewport/GrandmaSalmonSprite/GrandmaHead.play("default")

func get_snatcher_pos() -> Vector3:
	return $RockSnatch.global_position

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _physics_process(delta: float) -> void:
	if _moving:
		_t += delta * speed
		global_position = _from.lerp(_to, _t)
		
		# angle grandma_salmon to face the camera
		look_at(get_viewport().get_camera_3d().global_position)
		rotation.z = 0.0
		rotation.x = 0.0
		
		# sample the right curve at the t point to get the height
		if _step == 1:
			speed = 0.2
			global_position.y += heaven_curve.sample(_t) * Y_MULTIPLIER
		else:
			global_position.y += movement_curve.sample(_t) * Y_MULTIPLIER
		if _t > 1.00:
			_moving = false
			on_movement_finished.emit()
