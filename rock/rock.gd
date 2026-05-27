extends RigidBody3D

"""
Notes from Yollaine:
I changed the CurrentRockCollision's shape type to be ConvexPolygonShape3D which allows
the rock to actually collide with the floor rather than just fall through it which is
what was happening with the ConcavePolygonShape3D.

ConcavePolygonShape3D uses the set_points() function which luckily takes
PackedVector3Arrays. So it was quite easy to switch over to using that. However, I
notice that the mesh's edges are constantly appearing and disappearing with each kick
interpolation but it doesn't seem to mess with the collision of the rock itself.
Hopefully this won't become a problem in the future as this is the only solution I see
working right now.
"""

# how far along in the interpolation the shape of the rock is
@export var progress: float = 0.0

# camera-related parameters

# rotate 1 degree per frame, one turn every 6 seconds
@export var rotation_speed = TAU / 360

# camera tilted 30 degrees down on idle
@export var tilt_down = TAU / 12

# vector arrays for current, starting, and spherical ending rock shapes,
# respectively
var current_rock_vertices = PackedVector3Array()
var starting_rock_vertices = PackedVector3Array()
var ending_rock_vertices = PackedVector3Array()

# array to store distance between corresponding vertices of current and ending
# rock shapes; used in interpolation algorithm
var vertex_dists: Array[float]

# vector to use for the kick impulse
var kick_vector = Vector3(0.25, 0.1, 0.25)

# position of the rock on previous frame
# (check if this is different from current rock pos so that the camera pos
# isn't necessarily set on every frame)
var last_rock_pos = Vector3()

# interpolates the entire shape of the rock;
# vertices that start further out are biased to interpolate faster at first
func _interpolate(start: PackedVector3Array, end: PackedVector3Array,\
		dists: Array[float], progress: float) -> PackedVector3Array:
	progress = clamp(progress, 0, 1)
	var out = PackedVector3Array()
	for i in range(start.size()):
		out.push_back(start[i].lerp(end[i],\
				progress ** (0.002 / (dists[i] ** 2))))
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

func _on_change_state(new_state: GameManager.gamestates, _cause: String) -> void:
	match new_state:
		GameManager.gamestates.ROCK_KICKED:
			progress += 0.01
			if progress > 1:
				progress = 1
			print(progress)
			
			# change the rock shape
			current_rock_vertices =\
					_interpolate(starting_rock_vertices, ending_rock_vertices,\
					vertex_dists, progress)
			$CurrentRockCollision.shape.set_points(current_rock_vertices)
			$CurrentRockMesh.mesh = _set_color_mesh(current_rock_vertices)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	starting_rock_vertices = $StartingRockCollision.shape.get_faces()
	ending_rock_vertices = $SphericalRockCollision.shape.get_faces()
	for i in range(starting_rock_vertices.size()):
		vertex_dists.push_back(starting_rock_vertices[i].distance_to(\
				ending_rock_vertices[i]))
	
	GameManager.gamestate_update.connect(_on_change_state)
	# TODO: Eventually the starting rock vertices will depend on the number
	# of kicks left which perhaps the progress variable can be changed
	# based on that
	
	# For now, the rock starts with the starting rock vertices
	# To be deleted later
	$CurrentRockCollision.shape.set_points(starting_rock_vertices)
	$CurrentRockMesh.mesh = _set_color_mesh(starting_rock_vertices)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	# orbit camera if rock has moved less than 1 micron
	if self.position.distance_to(last_rock_pos) < 0.000001:
		$RockCameraPivot.rotation.y += rotation_speed
		$RockCameraPivot.rotation.x = -tilt_down
	# update set rock camera pivot and update last rock position
	else:
		$RockCameraPivot.position = self.position
		last_rock_pos = self.position
	# always make rock camera look at rock
	%RockCamera.look_at(self.position)
