extends Node3D

@onready var conifer_tree_multimesh: MultiMesh = $ConiferTrees.multimesh
@onready var deciduous_tree_multimesh: MultiMesh = $DeciduousTrees.multimesh
@onready var conifer_collision_body: PackedScene = preload("res://level_grids/park/trees/conifer_tree_collision_body.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_add_collision_to_trees()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _add_collision_to_trees() -> void:
	for i in range(conifer_tree_multimesh.instance_count):
		var conifer_collision: StaticBody3D = conifer_collision_body.instantiate()
		conifer_collision.set_transform(conifer_tree_multimesh.get_instance_transform(i))
		$ConiferStaticBodies.add_child(conifer_collision)
		
	for i in range(deciduous_tree_multimesh.instance_count):
		var conifer_collision: StaticBody3D = conifer_collision_body.instantiate()
		conifer_collision.set_transform(deciduous_tree_multimesh.get_instance_transform(i))
		$ConiferStaticBodies.add_child(conifer_collision)

# iterates through each multimesh and makes its basis an identity matrix
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
