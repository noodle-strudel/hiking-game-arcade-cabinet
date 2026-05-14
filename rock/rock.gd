extends RigidBody3D

# how far along in the interpolation the shape of the rock is
@export var progress = 0

# vector arrays for current, starting, and spherical ending rock shapes,
# respectively
var current_rock_vertices = PackedVector3Array()
var starting_rock_vertices = PackedVector3Array()
var ending_rock_vertices = PackedVector3Array()

# array to store distance between corresponding vertices of current and ending
# rock shapes; used in interpolation algorithm
var vertex_dists: Array[float]

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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	starting_rock_vertices = $StartingRockCollision.shape.get_faces()
	ending_rock_vertices = $SphericalRockCollision.shape.get_faces()
	for i in range(starting_rock_vertices.size()):
		vertex_dists.push_back(starting_rock_vertices[i].distance_to(\
				ending_rock_vertices[i]))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# only change rock shape when kicked
	if Input.is_action_just_pressed("test_kick"):
		progress += 0.01
		if progress > 1:
			progress = 1
		print(progress)
		current_rock_vertices =\
				_interpolate(starting_rock_vertices, ending_rock_vertices,\
				vertex_dists, progress)
				
		$CurrentRockCollision.shape.set_faces(current_rock_vertices)
