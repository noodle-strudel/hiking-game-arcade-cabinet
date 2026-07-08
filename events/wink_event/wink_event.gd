extends Event


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	process_mode = Node.PROCESS_MODE_ALWAYS


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _event_function() -> void:
	# Get the rock node from the main scene and the rock camera.
	var main_scene = get_tree().current_scene
	var rock = main_scene.get_node("Rock")
	var rock_camera = main_scene.get_node("Rock/RockCameraPivot/RockCameraArm/RockCamera")
	
	# Let the kick impulse happen first
	await get_tree().create_timer(0.5).timeout

	# Switch camera to the flying rock
	rock_camera.make_current()
	
	# Freeze game and have the rock wink.
	get_tree().paused = true
	await rock.wink_at_camera(rock_camera)
	get_tree().paused = false
	
	# Do not remove. Defined in event_base.gd
	_event_cleanup()
