extends Event

@onready var rock: Node = get_node("/root/Main/Rock")
@onready var rock_trail: Node = rock.get_node("%RockKickTrail")
@onready var main: Node = get_node("/root/Main")
@onready var camera: Camera3D = $UfoCamera
var cam_target: Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Camera following logic
	if is_instance_valid(cam_target):
		camera.look_at(cam_target.global_position)
		var cam_distance = camera.global_position\
				.distance_to(cam_target.global_position)
		
		# camera smooth zooming when the ufo gets further away
		# smooth move up as well for nicer angle
		if (
			cam_distance > 200.0 and
			camera.fov > 15
		):
			camera.global_position += Vector3(0,2,0)
			camera.fov -= 1
		elif (
			cam_distance > 250.0 and
			camera.fov > 10
		):
			camera.fov -= 1


func _event_function() -> void:
	# Define your event code in here.
	var spawn_position = main.get_spawn()
	
	# Waits for rock to be at peak of kick to do the ufo
	get_tree().paused = false
	await rock.descending
	get_tree().paused = true
	
	# await because main.gd waits to change camera;
	# that wait will overwrite the event camera on kicks where
	# descending takes less than 0.5 seconds it can probably be 
	# less than this but this is to be safe
	await get_tree().create_timer(0.3).timeout
	
	$UfoSound.play()
	
	await get_tree().create_timer(0.2).timeout
	
	# sets up the camera focused on the rock as it goes up
	cam_target = rock
	camera.global_position = cam_target.global_position + Vector3(100, 150, -100)
	camera.fov = 15
	camera.make_current()
	
	# hide rock trail so it doesn't jump up to the UFO position
	# when the rock is released (this disables it until the next kick)
	rock_trail.hide()
	
	# spawns the ufo in above the rock
	# and waits for the beam to be fully extended
	$Ufo.show()
	$Ufo.global_position = rock.global_position + Vector3(0.0, 300.0, 0.0)
	$Ufo/AnimationPlayer.play("BeamAnimation")
	await get_tree().create_timer(2.75).timeout
	
	var tween_up = create_tween()
	
	# Tween rock up in 2 seconds (this speed because the animation length)
	tween_up.tween_property(
		rock,
		"global_position",
		$Ufo.global_position,
		2.0
	)
	
	# Switches the camera to the ufo as it flies away
	await $Ufo/AnimationPlayer.animation_finished
	cam_target = $Ufo
	camera.fov = 30
	camera.global_position = $Ufo.global_position + Vector3(75, 75, -75)
	
	# Ufo and rock both move to the same random spawn point in the current grid
	var tween_away = create_tween()
	tween_away.tween_property(
		rock,
		"global_position",
		spawn_position + Vector3(0.0, 300.0, 0.0),
		10.0
	)
	tween_away.parallel().tween_property(
		$Ufo, 
		"global_position",
		spawn_position + Vector3(0.0, 300.0, 0.0),
		10.0
	)
	rock.linear_velocity = Vector3.ZERO
	
	
	await get_tree().create_timer(11.2).timeout
	
	# unpause early so the sound can finish playing as the rock is falling
	get_tree().paused = false
	
	# rock falls for a little bit, then the camera switches back
	await get_tree().create_timer(0.8).timeout
	main.rock_camera.make_current()
	
	await get_tree().create_timer(2.25).timeout
	
	# Do not remove. Defined in event_base.gd
	_event_cleanup()
