extends Event

@export var movement_curve: Curve
@export var speed: float = 1.5

@onready var rock: Node = get_node("/root/Main/Rock")
@onready var raycast_down: RayCast3D = $BirdBody/Bird/DetectGround
@onready var camera: Camera3D = $BirdCamera

var run_physics: bool = false
var direction: Vector3
var start_pos: Vector3
var end_pos: Vector3
var hop_timer: float = 0.0
var hop_duration: float = 0.5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _physics_process(delta: float) -> void:
	# Run physics bool is so the tween only starts once
	# and so the moving doesn't start until bird is in proper position
	if run_physics:
		var distance_to_rock = %BirdBody.position\
				.distance_to(rock.position)
		
		# Stops the bird when it is 1 away from the rock before it jumps on it
		if distance_to_rock > 1.0:
			if not %BirdBody.is_on_floor():
				%BirdBody.velocity.y += -1.0 * delta
			direction = %BirdBody.position\
					.direction_to(rock.position)
			
			# Handles the slopes so the bird goes up and down slopes
			if %BirdBody.is_on_floor():
				var floor_normal = %BirdBody.get_floor_normal()
				%Bird.quaternion = Quaternion(Vector3.UP, floor_normal)
			
			# Moving in x and z directions
			%BirdBody.velocity.x = move_toward(
				%BirdBody.velocity.x,
				direction.x * speed,
				10.0 * delta
			)
			%BirdBody.velocity.z = move_toward(
				%BirdBody.velocity.z,
				direction.z * speed,
				10.0 * delta
			)
			
			%BirdBody.move_and_slide()
			
			# Bird hopping along curve logic
			hop_timer += delta
			if hop_timer > hop_duration:
				hop_timer -= hop_duration 
				
			var weight = hop_timer / hop_duration
			if movement_curve != null:
				# Bounces the visual mesh only so physics and
				# Collision remain on the ground as it moves
				# Multiplier controls hop height.
				%Bird.position.y = movement_curve.sample(weight) * 0.3
		else:
			run_physics = false
			
			# Position set to local 0 (where the colision hits ground)
			# Does so before hop onto rock incase it is mid-hop when it would begin
			%Bird.position.y = 0.0
			_start_hop()


func _start_hop() -> void:
	# Does a tween for the final hop onto the rock
	start_pos = %BirdBody.global_position
	end_pos = rock.global_position + Vector3(0.0, 0.175, 0.0)
	var tween = create_tween()
	tween.tween_method(_process_hop, 0.0, 1.0, 1.0)
	await tween.finished
	
	# Post bird on rock code
	# changes camera and starts look around animation
	camera.global_position = %BirdBody.global_position + Vector3(-2.0, 0.5, 0.0)
	camera.look_at(%BirdBody.global_position)
	camera.fov = 50.0
	%Bird/AnimationPlayer.play("look_around")


func _process_hop(weight: float) -> void:
	# Processes the hop onto the rock animation based one the exported curve
	var current_pos = start_pos.lerp(end_pos, weight)
	var curve_height = movement_curve.sample(weight)
	
	current_pos.y += curve_height
	%BirdBody.global_position = current_pos


func _event_function() -> void:
	# Define your event code in here.
	
	# Bird spawns in the air and warps down to the ground
	# This is done to avoid spawning already in the ground
	%BirdBody.position = rock.position + Vector3(20.0, 25.0, 0.0)
	raycast_down.force_raycast_update()
	if raycast_down.is_colliding():
		%BirdBody.position = raycast_down.get_collision_point()
	run_physics = true
	
	# Camera logic same as player walk to rock camera
	# gives a side angle while the bird is hopping to the rock
	direction = %BirdBody.position\
			.direction_to(rock.position)
	var midpoint = (%BirdBody.global_position + rock.global_position) / 2.0
	var right = direction.cross(Vector3.UP).normalized()
	camera.global_position = midpoint + (right * 7.5) + Vector3(0.0, 2.0, 0.0)
	camera.look_at(midpoint)
	camera.fov = 90.0
	camera.make_current()
	
	# timer for the event it takes about 15-20 seconds to get to the rock
	# the 80 other seconds is how long it stays and can be adjusted
	await get_tree().create_timer(100).timeout
	
	# Do not remove. Defined in event_base.gd
	_event_cleanup()
