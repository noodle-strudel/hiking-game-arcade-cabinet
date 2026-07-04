extends Event


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _event_function() -> void:
	await get_tree().create_timer(5).timeout
	_event_cleanup()
