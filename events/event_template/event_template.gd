extends Event


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _event_function() -> void:
	# Define your event code in here.
	
	
	# Do not remove. Defined in event_base.gd
	_event_cleanup()
