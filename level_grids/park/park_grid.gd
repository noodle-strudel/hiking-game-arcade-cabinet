extends Grid
class_name ParkGrid

# multimeshes for the trees
@onready var conifer_tree_multimesh: MultiMesh = %ConiferTrees.multimesh
@onready var deciduous_tree_multimesh: MultiMesh = %DeciduousTrees.multimesh

# small amount of deciduous trees in the "no tree" part of the park mesh
@onready var deciduous_tree_sparse_multimesh: MultiMesh = %DeciduousTreesSparseNoTrees.multimesh

# static body collision shape for the trees
@onready var conifer_collision_body: PackedScene = preload("res://level_grids/park/trees/conifer_tree_collision_body.tscn")

@onready var spawn_points: Array[Marker3D]

func get_spawn_position() -> Vector3:
	var marker = spawn_points.pick_random()
	print("ROCKSPAWN #", marker.name)
	return marker.global_position

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	spawn_points = []
	for child in $SpawnPoints.get_children():
		if child is Marker3D:
			spawn_points.append(child)
	#_make_trees_point_up()
	#_save_convex_from_concave($rock_kicking_park_ground_new/StaticBody3D/CollisionShape3D.shape)
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _space_out_trees() -> void:
	# conifer trees
	var nudge: Vector3 = Vector3.ZERO
	for i in range(conifer_tree_multimesh.instance_count):
		var current_transform: Transform3D = conifer_tree_multimesh.get_instance_transform(i)
		var default_basis = Basis()
		var new_transform = Transform3D(default_basis, current_transform.origin)
		conifer_tree_multimesh.set_instance_transform(i, new_transform)
		
		# attempt to space out the trees
		# this is probably a really bad algo time complexity-wise 
		# so this should not be used multiple times
		for j in range(conifer_tree_multimesh.instance_count):
			var compare_transform: Transform3D = conifer_tree_multimesh.get_instance_transform(j)
			if compare_transform.origin != current_transform.origin:
				if compare_transform.origin.distance_to(current_transform.origin) < 5:
					nudge += current_transform.origin.direction_to(compare_transform.origin).normalized()
					print(nudge.length())
					new_transform = Transform3D(default_basis, current_transform.origin + nudge)
					conifer_tree_multimesh.set_instance_transform(i, new_transform)
	

# iterates through each multimesh and makes its basis an identity matrix, then
# saves it to the file system. for development only
func _make_trees_point_up() -> void:
	for i in range(conifer_tree_multimesh.instance_count):
		var current_transform: Transform3D = conifer_tree_multimesh.get_instance_transform(i)
		var default_basis = Basis()
		var new_transform = Transform3D(default_basis, current_transform.origin)
		conifer_tree_multimesh.set_instance_transform(i, new_transform)
		
	for i in range(deciduous_tree_multimesh.instance_count):
		var current_transform: Transform3D = deciduous_tree_multimesh.get_instance_transform(i)
		var default_basis = Basis()
		var new_transform = Transform3D(default_basis, current_transform.origin)
		deciduous_tree_multimesh.set_instance_transform(i, new_transform)
	ResourceSaver.save(conifer_tree_multimesh, "res://conifer_multimesh.tres")
	ResourceSaver.save(deciduous_tree_multimesh, "res://deciduous_multimesh.tres")

# takes a concave shape, makes it convex and then saves it to the file system.
func _save_convex_from_concave(concave: ConcavePolygonShape3D) -> void:
	var convex: ConvexPolygonShape3D = ConvexPolygonShape3D.new()
	convex.set_points(concave.get_faces())
	
	ResourceSaver.save(convex, "res://rock_kicking_park_ground_convex_collision.tres")

func _on_oob_barrier_body_entered(body: Node3D) -> void:
	if body.name == "Rock":
		GameManager.switch_state_to(GameManager.gamestates.ROCK_OOB, "The rock fell through the ground...")

func _on_lake_barrier_body_entered(body: Node3D) -> void:
	if body.name == "Rock":
		GameManager.switch_state_to(GameManager.gamestates.ROCK_OOB, "The rock fell in the lake...")
