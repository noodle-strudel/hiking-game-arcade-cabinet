extends Event


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _event_function() -> void:
	# Unpauses so the ow happens as rock is moving.
	get_tree().paused = false
	$OuchPlayer.play()
	# Timer to let the ouch play before being freed by event cleanup.
	await get_tree().create_timer(1).timeout
	
	# Do not remove. Defined in event_base.gd
	_event_cleanup()
