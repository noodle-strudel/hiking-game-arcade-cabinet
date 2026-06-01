extends Node3D

@onready var _anim = $AnimationPlayer

func play_kick() -> void:
	_anim.play("PantsKick")
