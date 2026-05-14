extends RigidBody3D

# how far along in the interpolation the shape of the rock is
@export var progress = 0

# vector arrays for current, starting, and spherical ending rock shapes,
# respectively
var current_rock_vertices = PackedVector3Array()
var starting_rock_vertices = PackedVector3Array()
var ending_rock_vertices = PackedVector3Array()

# interpolates the entire shape of the rock
func _interpolate(start: PackedVector3Array, end: PackedVector3Array,\
		progress: float) -> PackedVector3Array:
	progress = clamp(progress, 0, 1)
	var out = PackedVector3Array()
	for i in range(start.size()):
		out.push_back(start[i].lerp(end[i], progress))
	return out

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	starting_rock_vertices = $StartingRockCollision.shape.get_faces()
	ending_rock_vertices = $SphericalRockCollision.shape.get_faces()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# only change rock shape when kicked
	if Input.is_action_just_pressed("test_kick"):
		progress += 0.1
		if progress > 1:
			progress = 1
		print(progress)
		current_rock_vertices =\
				_interpolate(starting_rock_vertices, ending_rock_vertices,\
				progress)
				
		$CurrentRockCollision.shape.set_faces(current_rock_vertices)
