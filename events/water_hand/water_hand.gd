extends Node3D

@onready var remote_transform: RemoteTransform3D = $RockSnatchPos
@onready var hand: Skeleton3D = $WaterHandArmature/Skeleton3D
@onready var rock_bone_idx: int = hand.find_bone("rockpos")
@onready var rock_bone_transform: Transform3D = hand.get_bone_global_pose(rock_bone_idx)
@onready var rock_pos: Vector3 = hand.to_global(rock_bone_transform.origin)


func snatch_object(obj: NodePath) -> void:
	$RockSnatchPos.set_remote_node(obj)


func release_object() -> void:
	if $RockSnatchPos.remote_path:
		$RockSnatchPos.set_remote_node("")


func go_under_water() -> void:
	$AnimationPlayer.play("rock_snatch")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$AnimationPlayer.play("catch_rock_reset")
	$AnimationPlayer.play("catch_rock_go")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	rock_bone_transform = hand.get_bone_global_pose(rock_bone_idx)
	rock_pos = hand.to_global(rock_bone_transform.origin)
	remote_transform.global_position = rock_pos
