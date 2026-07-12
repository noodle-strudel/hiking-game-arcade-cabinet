extends Node3D
class_name Grid

signal modify_multimesh_complete

## The node that will hold all the StaticBody3D nodes.
@export var object_collisions_node: Node3D

## Dictionary pairs of multimeshes and corresponding StaticBody3D packed scenes.
@export var mulmesh_col_dict: Dictionary[MultiMesh, PackedScene]

var modifying_multimeshes: bool = false

# adds a staticbody3d for each multimesh object. 
# I read that it can be more efficient this way than adding a ton of collision 
# shapes to a single staticbody3d. Plus i'm able to add the transform to the 
# staticbody3d much easier than a collisionshape3d.
func add_collision_to_multimeshes() -> void:
	_await_modification()
	modifying_multimeshes = true
	if object_collisions_node and !object_collisions_node.get_children():
		for mulmesh in mulmesh_col_dict:
			for i in range(mulmesh.instance_count):
				var collision: StaticBody3D = mulmesh_col_dict[mulmesh].instantiate()
				collision.set_transform(mulmesh.get_instance_transform(i))
				object_collisions_node.add_child(collision)
	modifying_multimeshes = false
	modify_multimesh_complete.emit()

func remove_collisions_from_multimeshes() -> void:
	_await_modification()
	modifying_multimeshes = true
	if object_collisions_node:
		for child in object_collisions_node.get_children():
			if is_instance_valid(child):
				child.queue_free()
			
			# stagger queue_free to avoid lag spike
			await get_tree().physics_frame
	modifying_multimeshes = false
	modify_multimesh_complete.emit()

func _await_modification() -> void:
	if modifying_multimeshes:
		print("GRID: multimesh deletion occuring, please wait")
		await modify_multimesh_complete

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
