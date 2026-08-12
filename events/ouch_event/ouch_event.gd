extends Event


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _event_function() -> void:
	# Access UI kickbar
	var main_scene = get_tree().current_scene
	var ui = main_scene.get_node("UI")
	var kickbar = ui.get_node("%Kickbar")
	var rock = main_scene.get_node("Rock")
	
	# delay the ow sfx if it's a critical kick
	if kickbar.value >= ui.crit_threshold:
		await get_tree().create_timer(ui.hitstop_length).timeout

	# Unpauses so the ow happens as rock is moving.
	get_tree().paused = false
	$OuchPlayer.play()
	
	# toggle the rock's angry sprite
	rock.rock_anger_toggle(true)

	# Timer to let the ouch and angry sprite play before being freed by event cleanup.
	await get_tree().create_timer(3).timeout
	rock.rock_anger_toggle(false)
	
	# Do not remove. Defined in event_base.gd
	_event_cleanup()
