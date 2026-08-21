extends Event


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _event_function() -> void:
	%GrandmaHead.play()
	await $GSSpeech.finished
	%GrandmaHead.pause()
	_event_cleanup()
