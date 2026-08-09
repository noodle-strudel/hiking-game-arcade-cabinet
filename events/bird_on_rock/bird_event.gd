extends Event

@export var movement_curve: Curve
@export var speed: float = 1.5

@onready var rock: Node = get_node("/root/Main/Rock")
@onready var player: Node = get_node("/root/Main/Player")
@onready var raycast: RayCast3D = $BirdBody/Bird/SpawnDetector
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
	camera.global_position = %BirdBody.global_position + Vector3(-3.0, 1.0, -1.0)
	camera.look_at(%BirdBody.global_position)
	camera.fov = 50.0
	%Bird/AnimationPlayer.play("look_around")


func _process_hop(weight: float) -> void:
	# Processes the hop onto the rock animation based one the exported curve
	var current_pos = start_pos.lerp(end_pos, weight)
	var curve_height = movement_curve.sample(weight)
	
	current_pos.y += curve_height
	%BirdBody.global_position = current_pos

func _find_valid_spawn() -> Vector3:
	var fallback_pos: Vector3 = rock.global_position + Vector3(3.0, 50, 0.0)
	var valid_pos: Vector3 = fallback_pos
	var found_spot: bool = false
	var original_target: Vector3 = raycast.target_position
	var original_mask: int = raycast.collision_mask
	
	# Checks a spawn point 20m away at every degree in a circle around the rock
	# (Does NOT keep checking after finding a valid spawn)
	for i in range(0, 360, 1):
		var rad: float = deg_to_rad(i)
		var offset: Vector3 = Vector3(cos(rad) * 20, 50, sin(rad) * 20)
		var test_pos: Vector3 = rock.global_position + offset
		
		%BirdBody.global_position = test_pos
		
		# Check straight down for ground, OOB or building
		# this reset is so if during the building check it hits the continue
		# the collision mask would only be buildings
		raycast.target_position = original_target
		raycast.collision_mask = original_mask
		raycast.force_raycast_update()
		
		if not raycast.is_colliding():
			continue 
		
		var hit_collider = raycast.get_collider()
		if hit_collider is CollisionObject3D:
			# Rejects the spawnpoint if there is a building or OOB below
			# (collider is first thing ray hits) 
			if (
				hit_collider.get_collision_layer_value(7) or 
				hit_collider.get_collision_layer_value(8)
			):
				continue
		
		# If the spawn point is above ground then it checks for buildings
		
		var ground_pos: Vector3 = raycast.get_collision_point()
		
		# Check for buildings in the way from the bird to the rock
		%BirdBody.global_position = ground_pos + Vector3(0, 0.5, 0)
		var rock_center: Vector3 = rock.global_position + Vector3(0, 0.5, 0)
		
		raycast.target_position = raycast.to_local(rock_center)
		
		# Sets the collision mask to only buildings
		# makes sure ground on a slope doesn't invalidate a spawnpoint
		raycast.collision_mask = 0
		raycast.set_collision_mask_value(8, true) # Building
		raycast.force_raycast_update()
		
		if raycast.is_colliding():
			continue 
		
		# If there is no building in the way it checks the path
		
		# Check if the path is safe
		# this checks for gaps in the path (like the lake)
		# it fixes if the bird spawns safely but the lake is
		# in the way and it would fall in
		var distance_to_rock: float = ground_pos.distance_to(rock.global_position)
		var flat_direction: Vector3 = ground_pos.direction_to(rock.global_position)
		flat_direction.y = 0 
		flat_direction = flat_direction.normalized()
		
		var path_is_safe: bool = true
		var step_distance: float = 1.0 
		var current_dist: float = step_distance
		
		while current_dist < distance_to_rock:
			var check_point: Vector3 = ground_pos + (flat_direction * current_dist)
			%BirdBody.global_position = check_point + Vector3(0, 25.0, 0)
			
			# Reset to the original mask and target as that is what this
			# segment of the check needs
			raycast.target_position = original_target
			raycast.collision_mask = original_mask
			raycast.force_raycast_update()
			
			# Raycast should always collide it does nothing if colliding ground
			# it sets the path safety to false if it hits OOB and
			# goes to the next degree to check
			if raycast.is_colliding():
				var path_hit = raycast.get_collider()
				if (
					path_hit is CollisionObject3D and 
					path_hit.get_collision_layer_value(7)
				):
					path_is_safe = false
					break
			# Failsafe if ray is colliding with nothing at all
			else:
				path_is_safe = false
				break
				
			current_dist += step_distance
		
		if not path_is_safe:
			continue 
		
		# Passed all checks spawn is valid
		valid_pos = test_pos
		found_spot = true
		break
	
	# Reset raycast position
	raycast.target_position = original_target
	raycast.collision_mask = original_mask
	
	if not found_spot:
		push_warning("Bird Event: No valid spawn, using fallback spawn.")
	return valid_pos 

func _event_function() -> void:
	# Define your event code in here.
	
	player.hide()
	
	# Bird spawns in the air and warps down to the ground
	# This is done to avoid spawning already in the ground
	%BirdBody.position = _find_valid_spawn()
	raycast.force_raycast_update()
	if raycast.is_colliding():
		%BirdBody.position = raycast.get_collision_point()
	
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
	%Bird.look_at(rock.global_position, Vector3.UP)
	run_physics = true
	# timer for the event it takes about 15-20 seconds to get to the rock
	# the rest is how long it stays and can be adjusted
	await $StopTimer.timeout
	
	player.show()
	
	# Do not remove. Defined in event_base.gd
	_event_cleanup()
