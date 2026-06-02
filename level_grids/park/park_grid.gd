extends Node3D

# multimeshes for the trees
@onready var conifer_tree_multimesh: MultiMesh = $ConiferTrees.multimesh
@onready var deciduous_tree_multimesh: MultiMesh = $DeciduousTrees.multimesh

# static body collision shape for the trees
@onready var conifer_collision_body: PackedScene = preload("res://level_grids/park/trees/conifer_tree_collision_body.tscn")

"""PUBLIC CONSTANTS SINCE THE PARK GRID ACTS LIKE A CONTAINER OF INFO LIKE A NODE"""
const top: Vector3 = Vector3(0, 0, -250.0)
const left: Vector3 = Vector3(-250.0, 0, 0)
const right: Vector3 = Vector3(250.0, 0, 0)
const bottom: Vector3 = Vector3(0, 0, -250.0)
const top_left: Vector3 = top + left
const top_right: Vector3 = top + right
const bottom_left: Vector3 = bottom + left
const bottom_right: Vector3 = bottom + right

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#_make_trees_point_up()
	#_save_convex_from_concave($rock_kicking_park_ground_new/StaticBody3D/CollisionShape3D.shape)
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# adds a staticbody3d for each tree in a radius around a given point. I read that it can be more efficient this way
# than adding a ton of collision shapes to a single staticbody3d. Plus i'm able to
# add the transform to the staticbody3d much easier than a collisionshape3d.
# TODO: experiment with making a shape for the deciduous tree
func add_collision_to_trees() -> void:
	print($TreeStaticBodies.get_children())
	if (!$TreeStaticBodies.get_children()):
		for i in range(conifer_tree_multimesh.instance_count):
			var conifer_collision: StaticBody3D = conifer_collision_body.instantiate()
			conifer_collision.set_transform(conifer_tree_multimesh.get_instance_transform(i))
			$TreeStaticBodies.add_child(conifer_collision)
			
		for i in range(deciduous_tree_multimesh.instance_count):
			var deciduous_collision: StaticBody3D = conifer_collision_body.instantiate()
			deciduous_collision.set_transform(deciduous_tree_multimesh.get_instance_transform(i))
			$TreeStaticBodies.add_child(deciduous_collision)

func remove_collision_from_trees() -> void:
	for child in $TreeStaticBodies.get_children():
		child.queue_free()

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
		GameManager.switch_state_to(GameManager.gamestates.ROCK_OOB, "fell through the ground")
