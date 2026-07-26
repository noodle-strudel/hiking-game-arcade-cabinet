extends Event

@export var movement_curve: Curve
@onready var rock = get_node("/root/Main/Rock")
@onready var raycast_down = $BirdBody/Bird/DetectGround
@onready var run_physics = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _physics_process(delta: float) -> void:
	if run_physics:
		if not %BirdBody.is_on_floor():
			%BirdBody.velocity += %BirdBody.get_gravity() * delta
		
		var direction = Vector3.LEFT
		var speed = 1.5
		
		if %BirdBody.is_on_floor():
			var floor_normal = %BirdBody.get_floor_normal()
			_allign_slope(floor_normal, direction, delta)
		
		%BirdBody.velocity.x = move_toward(%BirdBody.velocity.x, direction.x * speed, 10.0 * delta)
		%BirdBody.velocity.z = move_toward(%BirdBody.velocity.z, direction.z * speed, 10.0 * delta)
		
		%BirdBody.move_and_slide()


func _allign_slope(floor_normal: Vector3, direction: Vector3, delta: float) -> void:
	var target_right = direction.cross(floor_normal).normalized()
	var target_basis = Basis(
		target_right,
		floor_normal,
		floor_normal.cross(target_right).normalized()
	)
	
	%Bird.global_basis = %Bird.global_basis.slerp(
		target_basis,
		10.0 * delta
	).orthonormalized()

func _event_function() -> void:
	# Define your event code in here.
	%BirdBody.position = rock.position + Vector3(20.0, 15.0, 0.0)
	raycast_down.force_raycast_update()
	if raycast_down.is_colliding():
		%BirdBody.position = raycast_down.get_collision_point()
	run_physics = true
	await get_tree().create_timer(30).timeout
	# Do not remove. Defined in event_base.gd
	_event_cleanup()
