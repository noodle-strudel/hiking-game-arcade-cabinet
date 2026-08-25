extends Node

## used by ui script to hide kicking ui after camera switch
signal rock_followcam_activated

# fallback option to keep the chunk code from breaking in extreme circumstances. 
@onready var _heaven_sun = preload("res://levels/purgatory/heaven_directional_light_3d.tscn")
@onready var grandma_salmon_helper_scene: PackedScene = preload(
	"res://events/grandma_salmon/helper/grandma_salmon_helper.tscn"
)

@onready var salmon_ascender := preload("res://events/grandma_salmon/ascension/salmon_ascension.tscn")

# Cameras
@onready var player_camera := $Player/CameraPivot/PlayerCamera
@onready var rock := $Rock
@onready var rock_camera := $Rock/RockCameraPivot/RockCameraArm/RockCamera
@onready var pan_camera := $PanningCamera
@onready var walk_camera := $PlayerWalkCamera

# the tween, used for tweening
@onready var tween: Tween = get_tree().create_tween()

# how much to smooth the walk camera angle 
@export var walk_camera_smoothing := 0.95

# variable to track what the panning camera should be doing
var camera_pan_state = 0
var panning_camera_active = false

# keep track of which camera the camera switcher should switch to on timeout
var camera_switch_tracker = 0

# variable to track if the rock should be being followed by the player
var follow_rock = false

# flag that is true when the player is moving
var player_moving = false

var walk_camera_look_at = Vector3()

func get_spawn() -> Vector3:
	return $WorldGeneration.get_spawn()

func _regular_idle_actions() -> void:
	rock_camera.make_current()
	%UIAnimator.play("idle_float")

## Event handler for gamestate_update. Changes the currently active camera. 
func _on_change_state(state: GameManager.gamestates, cause: String) -> void:
	$IdleIdleTimer.stop()
	%UIAnimator.play("RESET")
	player_moving = false
	match state:
		GameManager.gamestates.IDLE:
			$IdleIdleTimer.start()
			if cause == "player got to rock":
				# if the player walked to the rock sent the game to idle play
				# play the correct salmon stuff. This fixes the issue of the game
				# doing these animations on bootup at 8000 and 10000 kicks
				if GameManager.kicks_remaining == GameManager.heaven_kick_count:
					# salmon to heaven sequence
					# 5 second wait is for gates to open
					$UI.hide()
					await get_tree().create_timer(5.0).timeout
					var ascender = salmon_ascender.instantiate()
					self.add_child(ascender)
					await ascender.ascension_complete
					_load_heaven_environment()
					_load_heaven_sun()
					$WorldGeneration._load_heaven()
					$UI.show()
					
				elif GameManager.kicks_remaining == GameManager.purgatory_kick_count:
					# do salmon purgatory sequence
					$UI.hide()
					var ascender = salmon_ascender.instantiate()
					self.add_child(ascender)
					await ascender.ascension_complete
					_load_heaven_environment()
					_load_heaven_sun()
					$WorldGeneration._load_purgatory()
					$UI.show()
					$UI/KickingMenu/PurgKicksRemainingContainer.show()
					
				# go back to regular idle state stuff
				_regular_idle_actions()
			else:
				_regular_idle_actions()
		GameManager.gamestates.CONTRACT:
			
			# Pan timer stops so that the panning camera doesn't keep moving
			$IdleIdleTimer.stop()
			$CameraSwitchTimer.stop()
			camera_pan_state = 0
			player_camera.make_current()
		GameManager.gamestates.KICKING:
			player_camera.make_current()
		GameManager.gamestates.ROCK_KICKED:
			
			# wait a moment before switching camera to rock camera
			follow_rock = true
			
			await get_tree().process_frame
			# if a critical kick occurs, wait a longer time
			if GameManager.critical_kick:
				await get_tree().create_timer(0.8).timeout
			else:
				await get_tree().create_timer(0.5).timeout
			follow_rock = false
			rock_camera.make_current()
			rock_followcam_activated.emit()
		GameManager.gamestates.POSTKICK_EVENT:
			# wait for any events to be done
			await EventManager.event_clear
			
			# Caluculate the distance kicked.
			var kick_distance = $Player.global_position.distance_to($Rock.global_position)
			
			# Report the score.
			GameManager.report_score(
				GameManager.current_kick_strength,
				kick_distance
			)
			
			GameManager.switch_state_to(GameManager.gamestates.SCORING, "post kick event finished")
		GameManager.gamestates.SCORING:
			pass
		GameManager.gamestates.ROCK_OOB:
			_handle_oob(cause)
		GameManager.gamestates.MOVE_TO_ROCK:
			walk_camera_look_at = $Player.global_position
			var midpoint = ($Player.global_position + $Rock.global_position) / 2.0
			var walk_direction = $Player.global_position\
					.direction_to($Rock.global_position)
			var right = walk_direction.cross(Vector3.UP).normalized()
			
			# Sets the camera for the walking scene off to the right looking at the midpoint
			# between the player and the rock. (Adjust PlayerWalkCamera FOV to see more)
			walk_camera.global_position = midpoint + (right * 7.5) + Vector3(0.0, 3.0, 0.0)
			walk_camera.look_at(midpoint)
			walk_camera.make_current()
			player_moving = true
		GameManager.gamestates.ROCK_PERFECTED:
			if GameManager.DEBUG:
				print("MAIN: Kicks remaining at 0! Commence the forever sequence!")


# handle camera and state transition when rock goes out of bounds.
func _handle_oob(_cause: String) -> void:
	$Rock.camera_follow(false)
	if "snatch" in _cause:
		await get_tree().create_timer(6).timeout
	else:
		await get_tree().create_timer(1).timeout
	
	# summon grandma salmon to assist in moving the rock
	var g_sam: GrandmaSalmonHelper = grandma_salmon_helper_scene.instantiate()
	add_child(g_sam)
	g_sam.look_at(rock_camera.global_position)
	
	# save rock pos before its overridden by the remote transform
	var rock_pos_ref = rock.global_position
	g_sam.snatch_object(rock.get_path())  
	g_sam.move_obj(rock_pos_ref, $Player.position + Vector3(1, 1, 1))
	
	# wait for grandma to emerge
	await get_tree().create_timer(0.5).timeout
	$Rock.camera_follow(true)
	
	await g_sam.on_movement_finished
	rock.linear_velocity = Vector3.ZERO
	rock.global_position = g_sam.get_snatcher_pos()
	g_sam.release_object()
	g_sam.queue_free()
	
	if "snatch" in _cause:
		await get_tree().create_timer(2).timeout
	else:
		await get_tree().create_timer(4.5).timeout
	
	# Player kicks rock into lake, gets a score of 0, and their turn ends.
	if "lake" in _cause:
		GameManager.last_score = 0
		GameManager.switch_state_to(GameManager.gamestates.SCORING, "rock landed in lake")
	
	# Player kicks rock and it falls through the ground, the player gets to kick again.
	elif "ground" in _cause:
		GameManager.switch_state_to(GameManager.gamestates.KICKING)

# PURGATORY CODE=================================

# environment switcher
func _load_heaven_environment() -> void:
	# switch environment
	$WorldEnvironment.set_environment(load("res://levels/heaven_environment.tres"))

func _load_heaven_sun() -> void:
	# Change sun
	if get_node_or_null("MainDirectionalLight3D"):
		$MainDirectionalLight3D.queue_free()
		var sun = _heaven_sun.instantiate()
		add_child(sun)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	# connect signals
	GameManager.gamestate_update.connect(_on_change_state)
	
	if GameManager.kicks_remaining <= 0:
		GameManager.switch_state_to(GameManager.gamestates.ROCK_PERFECTED, "already perfect")
	else:
		GameManager.switch_state_to(GameManager.gamestates.IDLE, "Game booted")
	
	# Spawn rock and player at a random location in the current grid.
	var spawn_position = get_spawn()
	var random_y = deg_to_rad(randf_range(0.0, 360.0))
	
	rock.linear_velocity = Vector3.ZERO
	rock.angular_velocity = Vector3.ZERO
	rock.global_position = spawn_position
	
	$Player.current_y_rotation = random_y
	if GameManager.DEBUG:
		print("Spawn direction degrees: ", rad_to_deg($Player.current_y_rotation))
	$Player.global_position = spawn_position + Vector3(0, 0, 3)
	
	# Console commands that allow us to do many things and adding more is very easy
	Console.pause_enabled = true
	Console.add_command("tp",
		_console_teleport,
	)
	Console.add_command("set_kicks",
		_console_set_kick,
		["kicks remaining"],
		1,
		"Set kicks remaining"
	)
	Console.add_command("set_event",
		_console_set_event,
		["event number"],
		1,
		"Set active event (use a number)"
	)
	Console.add_command("set_state",
		_console_set_state,
		["state"],
		1,
		"Set active gamestate"
	)
	Console.add_command_autocomplete_list("set_state",
		["IDLE",
		"CONTRACT",
		"KICKING",
		"ROCK_KICKED",
		"POSTKICK_EVENT",
		"SCORING",
		"ROCK_OOB",
		"MOVE_TO_ROCK",
		"ROCK_PERFECTED",
		]
	)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if player_moving:
		_camera_follow_player()
	
	if panning_camera_active:
		_panning_camera()

func _camera_follow_player() -> void:
	walk_camera.look_at(walk_camera_look_at)
	
	walk_camera_look_at = $Player.global_position.lerp(
		walk_camera_look_at,
		walk_camera_smoothing
	)

# panning camera stuff
func _panning_camera() -> void:
	
	# cameras cannot have velocity, thus workarounds
	# rotation minorly changed every call
	pan_camera.rotate_y(0.001)
	if camera_pan_state == 0:
		camera_pan_state = 1
	elif camera_pan_state == 1:
		
		# sets the pan camera to properly look at the player
		pan_camera.position = $Player.position
		pan_camera.position.y += 30
		pan_camera.position.x += 45
		pan_camera.look_at($Player.position)
		camera_pan_state = 3
		
	# moves the pan cam in one direction, until too far from the player
	elif camera_pan_state == 2:
		if !tween.is_valid(): 
			tween = get_tree().create_tween()
			tween.set_ease(Tween.EASE_IN_OUT)
			tween.set_trans(Tween.TRANS_SINE)
			tween.tween_property(pan_camera, "position:x", $Player.position.x + 100, 30)
		if pan_camera.position.x > $Player.position.x + 99 :
			tween.kill()
			camera_pan_state = 3
			
	# moves the pan cam in other direction
	elif camera_pan_state == 3:
		if !tween.is_valid(): 
			tween = get_tree().create_tween()
			tween.set_ease(Tween.EASE_IN_OUT)
			tween.set_trans(Tween.TRANS_SINE)
			tween.tween_property(pan_camera, "position:x", $Player.position.x - 100, 30)
		if pan_camera.position.x < $Player.position.x - 99 :
			tween.kill()
			camera_pan_state = 2

# Teleport the player to the rock, if you wish to move around by kicking the rock
# and don't want to wait for the walking this is how
func _console_teleport() -> void:
	$Player.position = $Rock.position + Vector3(0.0, 0.0, 1.0)

# Set the kicks remaining, emits decrement signal of the kicks passed in
# making for easier work on changing loading segments
func _console_set_kick(kick: String) -> void:
	GameManager.kicks_remaining = kick.to_int()
	GameManager.decrement_kicks_remaining.emit(GameManager.kicks_remaining)

# Set the event that is currently active with a number
# This can be changed to be similar to the state change command but,
# that would be easier to do when the events are done being added
func _console_set_event(event: String) -> void:
	EventManager.event_value = event.to_int()
	if EventManager.event_value < EventManager.total_event_count:
		Console.print_line("That means event: " + str(EventManager.known_events[EventManager.event_value]))
	else:
		Console.print_line("That means event: NO_EVENT")

# Set the current state of the game, we still have the 1-5 number keys but those
# don't cover all gamestates currently in the game, when typing the command
# you can hit tab to cycle through the states, they are case sensitive
func _console_set_state(state: String) -> void:
	match state:
		"IDLE":
			GameManager.switch_state_to(GameManager.gamestates.IDLE, "Console")
		"CONTRACT":
			GameManager.switch_state_to(GameManager.gamestates.CONTRACT, "Console")
		"KICKING":
			GameManager.switch_state_to(GameManager.gamestates.KICKING, "Console")
		"ROCK_KICKED":
			GameManager.switch_state_to(GameManager.gamestates.ROCK_KICKED, "Console")
		"POSTKICK_EVENT":
			GameManager.switch_state_to(GameManager.gamestates.POSTKICK_EVENT, "Console")
		"SCORING":
			GameManager.switch_state_to(GameManager.gamestates.SCORING, "Console")
		"ROCK_OOB":
			GameManager.switch_state_to(GameManager.gamestates.ROCK_OOB, "Console")
		"MOVE_TO_ROCK":
			GameManager.switch_state_to(GameManager.gamestates.MOVE_TO_ROCK, "Console")
		"ROCK_PERFECTED":
			GameManager.switch_state_to(GameManager.gamestates.ROCK_PERFECTED, "Console")
		_:
			Console.print_line("State not recognized")


func _on_stairs_timer_timeout() -> void:
	if (
		GameManager.kicks_remaining <= GameManager.purgatory_kick_count and
		GameManager.kicks_remaining > GameManager.heaven_kick_count
	):
		# double check that purgatory is loaded
		if not $WorldGeneration.purgatory:
			print("ERROR: tried to go to purgatory stairs camera but no purgatory was found.")
			return
		
		# kick off animation
		$WorldGeneration.purgatory.stairs_camera_dolly()
		await $WorldGeneration.purgatory.stairs_camera_finished
		
		# go back to rock camera
		_regular_idle_actions()
	else:
		_regular_idle_actions()


func _on_camera_switch_timer_timeout() -> void:
	if camera_switch_tracker == 0:
		pan_camera.make_current()
		camera_switch_tracker = 1
	elif camera_switch_tracker == 1:
		camera_switch_tracker = 2
		_on_stairs_timer_timeout()
	else:
		_regular_idle_actions()
		camera_switch_tracker = 0


func _on_idle_idle_timer_timeout() -> void:
	$CameraSwitchTimer.start()
	panning_camera_active = true


func _on_world_generation_on_load_heaven() -> void:
	_load_heaven_environment()
	_load_heaven_sun()
	# Spawn rock and player at a random location in heaven. 
	var spawn_position = get_spawn()
	rock.global_position = spawn_position
	$Player.global_position = spawn_position + Vector3(0.0, 0.0, 1.0)


func _on_world_generation_on_load_purgatory() -> void:
	_load_heaven_environment()
	_load_heaven_sun()
	# teleport player and rock
	var init_spawn = $WorldGeneration.purgatory.get_spawn_position()
	$Player.position = init_spawn + Vector3(0.0, 0.0, 1.0)
	$Rock.position = init_spawn
