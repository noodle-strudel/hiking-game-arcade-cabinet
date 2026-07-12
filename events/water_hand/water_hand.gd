@tool
extends Node3D

@onready var remote_transform: RemoteTransform3D = $RockSnatchPos
@onready var hand: Skeleton3D = $WaterHandArmature/Skeleton3D
@onready var rock_bone_idx: int = hand.find_bone("rockpos")
@onready var rock_bone_transform: Transform3D = hand.get_bone_global_pose(rock_bone_idx)
@onready var rock_pos: Vector3 = hand.to_global(rock_bone_transform.origin)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	remote_transform.global_position = rock_pos
