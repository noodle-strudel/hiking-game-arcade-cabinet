extends Node3D

@onready var _anim = $AnimationPlayer

func play_kick() -> void:
	_anim.play("PantsKick")

func play_run() -> void:
	_anim.play("PantsRun")

func stop_run() -> void:
	_anim.stop()
