extends Node3D
class_name Grid

## The node that will hold all the StaticBody3D nodes.
@export var object_collisions_node: Node3D

## Dictionary pairs of multimeshes and corresponding StaticBody3D packed scenes.
@export var mulmesh_col_dict: Dictionary[MultiMesh, PackedScene]

# Array of spawn points where the rock can spawn when the game boots up.
var spawn_points: Array[Marker3D]

# Randomly chooses 1 of the 3 random spawn locations.
func get_spawn_position() -> Vector3:
	var marker = spawn_points.pick_random()
	print("Spawn: ", marker.name)
	return marker.global_position

# adds a staticbody3d for each multimesh object. 
# I read that it can be more efficient this way than adding a ton of collision 
# shapes to a single staticbody3d. Plus i'm able to add the transform to the 
# staticbody3d much easier than a collisionshape3d.
func add_collision_to_multimeshes() -> void:
	if object_collisions_node and !object_collisions_node.get_children():
		for mulmesh in mulmesh_col_dict:
			for i in range(mulmesh.instance_count):
				var collision: StaticBody3D = mulmesh_col_dict[mulmesh].instantiate()
				collision.set_transform(mulmesh.get_instance_transform(i))
				object_collisions_node.add_child(collision)

func remove_collisions_from_multimeshes() -> void:
	if object_collisions_node:
		for child in object_collisions_node.get_children():
			child.queue_free()
			
			# stagger queue_free to avoid lag spike
			await get_tree().physics_frame

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var spawn_point := get_node_or_null("SpawnPoints")
	
	if spawn_point:
		for child in spawn_point.get_children():
			if child is Marker3D:
				spawn_points.append(child)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
