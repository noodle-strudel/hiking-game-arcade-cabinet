extends Event


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _event_function() -> void:
	
	# mouth movement timings
	await get_tree().create_timer(2.4).timeout
	%GrandmaHead.pause()
	await get_tree().create_timer(0.25).timeout
	%GrandmaHead.play()
	await get_tree().create_timer(2).timeout
	%GrandmaHead.pause()
	await get_tree().create_timer(0.3).timeout
	%GrandmaHead.play()
	await get_tree().create_timer(0.8).timeout
	%GrandmaHead.pause()
	await get_tree().create_timer(0.45).timeout
	%GrandmaHead.play()
	await get_tree().create_timer(1.2).timeout
	%GrandmaHead.pause()
	await get_tree().create_timer(0.25).timeout
	%GrandmaHead.play()
	await get_tree().create_timer(1.6).timeout
	%GrandmaHead.pause()
	await get_tree().create_timer(1.75).timeout
	
	_event_cleanup()
