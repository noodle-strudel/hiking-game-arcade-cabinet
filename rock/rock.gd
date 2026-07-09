extends RigidBody3D

# how far along in the interpolation the shape of the rock is
@export var progress: float = 0.0

# rotate 1 degree per frame, one turn every 6 seconds
@export var rotation_speed: float = (TAU / 360) * 0.3

# camera tilted 30 degrees down on idle
@export var tilt_down: float = TAU / 12

var camera_orbiting: bool = true

# vector arrays for current, starting, and spherical ending rock shapes,
# respectively
var current_rock_vertices: PackedVector3Array
var starting_rock_vertices: PackedVector3Array
var ending_rock_vertices: PackedVector3Array

# array to store distance between corresponding vertices of current and ending
# rock shapes; used in interpolation algorithm
var vertex_dists: Array[float]

# vector to use for the kick impulse
var kick_vector := Vector3(0.25, 0.1, 0.25)

# position of the rock on previous frame
# (check if this is different from current rock pos so that the camera pos
# isn't necessarily set on every frame)
var last_rock_pos: Vector3

# position of rock on second-to-previous frame (for calculating deceleration)
var second_rock_pos: Vector3

"""Rock's Eyes's Control Functions"""

# align the rock's eyes with the camera
# NOTE: I've noticed it acts a little wonky when ran just once and needs to be
# called multiple times for the eyes to actually look at the camera
func rock_eyes_look_at(camera: Camera3D) -> void:
	$RockEyes.look_at(camera.global_position, Vector3.UP)

# play the rock's eye's wink anim and return the signal to wait for
# ex. 
# await rock.rock_eyes_wink()
func rock_eyes_wink() -> Signal:
	$RockEyes/AnimationPlayer.play("wink")
	return $RockEyes/AnimationPlayer.animation_finished

# the rock eyes face the player camera and winks, then goes back to original direction
func wink_at_camera(camera: Camera3D) -> void:
	rock_eyes_look_at(camera)
	await get_tree().create_timer(0.3).timeout
	
	await rock_eyes_wink()
	$RockEyes.rotation = Vector3.ZERO
	await get_tree().create_timer(0.3)
	
"""Rock's Functions"""

# interpolates the entire shape of the rock;
# vertices that start further out are biased to interpolate faster at first
func _interpolate(
	start: PackedVector3Array,
	end: PackedVector3Array,
	dists: Array[float],
	progress: float
) -> PackedVector3Array:
	progress = clamp(progress, 0, 1)
	var out = PackedVector3Array()

	# generate interpolated vertices
	for i in range(start.size()):
		out.push_back(
			start[i].lerp(end[i],
			progress ** (0.002 / (dists[i] ** 2)))
		)

	return out

# update shape of visible color mesh from the PackedVector3Array used by the
# collision mesh
func _set_color_mesh(src: PackedVector3Array) -> ArrayMesh:
	var surf_tool = SurfaceTool.new()
	surf_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in src:
		surf_tool.add_vertex(i)
	surf_tool.generate_normals()
	return surf_tool.commit()

func _get_progress() -> float:

	# progress is based off kicks remaining
	return 1.0 - (float(GameManager.kicks_remaining) / 1000000)

func _update_rock() -> void:

	# update interpolated rock shape
	current_rock_vertices = _interpolate(
		starting_rock_vertices,
		ending_rock_vertices,
		vertex_dists,
		progress
	)

	$CurrentRockCollision.shape.set_points(current_rock_vertices)
	$CurrentRockMesh.mesh = _set_color_mesh(current_rock_vertices)

func _on_change_state(new_state: GameManager.gamestates, _cause: String) -> void:
	camera_orbiting = false
	match new_state:
		GameManager.gamestates.ROCK_KICKED:
			$KickSoundPlayer.play()
			$KickTimer.start()
			progress = _get_progress()
			progress = clamp(progress, 0.0, 1.0)
			print("Progress: ", progress)

			# change the rock shape
			_update_rock()
		GameManager.gamestates.IDLE:
			camera_orbiting = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	starting_rock_vertices = $StartingRockCollision.shape.get_faces()
	ending_rock_vertices = $SphericalRockCollision.shape.get_faces()

	# get distances between respective starting and ending rock vertices
	for i in range(starting_rock_vertices.size()):
		vertex_dists.push_back(starting_rock_vertices[i].distance_to(
			ending_rock_vertices[i]
		))

	GameManager.gamestate_update.connect(_on_change_state)
	progress = _get_progress()
	progress = clamp(progress, 0.0, 1.0)
	_update_rock()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:

	# report to the game manager when the rock has come to a rest after being kicked
	if (
		GameManager.state == GameManager.gamestates.ROCK_KICKED and\
		$KickTimer.get_time_left() == 0.0 and\
		self.position.distance_to(last_rock_pos) < 0.000001
	):
		GameManager.switch_state_to(
			GameManager.gamestates.POSTKICK_EVENT,
			"rock came to a rest after being kicked"
		)

	# if rock was vertically falling before but suddenly lost a bunch of vertical speed,
	# then emit the dust particles
	if (
		last_rock_pos.y - second_rock_pos.y < -0.05 and\
		self.position.y - last_rock_pos.y > (last_rock_pos.y - second_rock_pos.y) / 3
	):
		%RockDustParticles.emitting = true

	# update old rock positions
	second_rock_pos = last_rock_pos
	last_rock_pos = self.position

	# orbit camera
	if camera_orbiting:
		$RockCameraPivot.rotation.y += rotation_speed
		$RockCameraPivot.rotation.x = -tilt_down

	# update set rock camera pivot and update last rock position
	$RockCameraPivot.position = self.position
	$RockEyes.position = self.position

	# always make rock camera look at rock
	%RockCamera.look_at(self.position)

	# control the size of the rock's trail
	%RockKickTrail.size = clamp((self.linear_velocity.length() / 20 ) - 0.3, 0.0, 0.3)
