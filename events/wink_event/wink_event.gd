extends Event

@onready var rock_material = preload("res://rock/rock_material.tres")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	process_mode = Node.PROCESS_MODE_ALWAYS


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _event_function() -> void:
	# TEST
	if GameManager.DEBUG:
		print("yo im winkin here!")
	
	# Get the rock node from the main scene and the rock camera.
	var main_scene = get_tree().current_scene
	var rock = main_scene.get_node("Rock")
	var rock_eyes = rock.get_node("RockEyes")
	var rock_camera = main_scene.get_node("Rock/RockCameraPivot/RockCameraArm/RockCamera")
	
	# Let the kick impulse happen first.
	get_tree().paused = false
	await rock.descending
	get_tree().paused = true
	# show eyes
	rock_eyes.show()
	
	# turn off xray for rock so it doesn't interfere with eyes
	rock_material.stencil_mode = BaseMaterial3D.STENCIL_MODE_DISABLED
	
	# Have the rock wink.
	await rock.wink_at_camera(rock_camera)
	rock_eyes.hide()
	
	# turn xray back on after event
	rock_material.stencil_mode = BaseMaterial3D.STENCIL_MODE_XRAY
	
	# Do not remove. Defined in event_base.gd.
	_event_cleanup()
