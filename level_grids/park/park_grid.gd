extends Node3D

@onready var conifer_tree_multimesh: MultiMesh = $ConiferTrees.multimesh
@onready var deciduous_tree_multimesh: MultiMesh = $DeciduousTrees.multimesh
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#for i in range(conifer_tree_multimesh.instance_count):
		#var current_transform: Transform3D = conifer_tree_multimesh.get_instance_transform(i)
		#var default_basis = Basis()
		#var new_transform = Transform3D(default_basis, current_transform.origin)
		#conifer_tree_multimesh.set_instance_transform(i, new_transform)
		#
	#for i in range(deciduous_tree_multimesh.instance_count):
		#var current_transform: Transform3D = deciduous_tree_multimesh.get_instance_transform(i)
		#var default_basis = Basis()
		#var new_transform = Transform3D(default_basis, current_transform.origin)
		#deciduous_tree_multimesh.set_instance_transform(i, new_transform)
	#ResourceSaver.save(conifer_tree_multimesh, "res://conifer_multimesh.tres")
	#ResourceSaver.save(deciduous_tree_multimesh, "res://deciduous_multimesh.tres")
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
