extends Node

# signal emitted from _process when the rock moves to a new "chunk".
# shift is a vector2 with the amount the rock has moved
# e.g., 
## Emitted when the rock moves to a new chunk. 
## ex: if the rock has moved to the next chunk in the -z direction,
## shift will be (0, -1)
signal grid_position_changed(shift: Vector2i)
## used by ui script to hide kicking ui after camera switch
signal rock_followcam_activated

## List of scenes that can be instantiated as chunks
@onready var _level_segments = [
	preload("res://level_grids/park/park_grid.tscn"),
	#preload("res://level_grids/heaven/heaven_grid.tscn"),
	preload("res://level_grids/city/city_grid.tscn"),
	#preload("res://level_grids/purgatory/surrounding_grids/purgatory_1_grid.tscn")
]

## List of scenes that can be instantiated as chunks when the number of kicks go down.
## Currently unused.
@onready var _low_kick_level_segments = [
	preload("res://level_grids/purgatory/heaven_stairs_grid.tscn"),
]

# fallback option to keep the chunk code from breaking in extreme circumstances. 
@onready var _none_level_segment = preload("res://level_grids/none/none_level_grid.tscn")
@onready var _purgatory = preload("res://levels/purgatory/purgatory.tscn")
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

# Width and breadth of the level segments
const _grid_x_dimension := 2 * 250.0
const _grid_z_dimension := 2 * 250.0 

## Current chunk displacement since game was instantiated. Ordered x, z. 
var grid_position := [0, 0] # x,z
var _last_grid_position := grid_position.duplicate()

# variable to track what the panning camera should be doing
var camera_pan_state = 0
var panning_camera_active = false

# keep track of which camera the camera switcher should switch to on timeout
var camera_switch_tracker = 0

# variable to track if the rock should be being followed by the player
var follow_rock = false

# flag that is true when the player is moving
var player_moving = false


# holds the reference to purgatory level, when instantiated
var purgatory = null

## The 2d array of currently loaded chunks, centered on the rock.
## Stores references to instantiated chunks. 
## Ordered as z, x. [1,1] is the current center of the grid.
var _current_chunks = [
	[null, null, null], # +x->
	[null, null, null],
	[null, null, null]
]	# +z
	# v

func get_spawn() -> Vector3:
	if purgatory:
		return purgatory.get_spawn_position()
	var grid: Grid = _current_chunks[1][1]
	var spawn_position: Vector3 = grid.get_spawn_position()
	return spawn_position

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
			if GameManager.kicks_remaining != GameManager.purgatory_kick_count:
				_regular_idle_actions()
			else:
				# do salmon purgatory sequence
				$UI.hide()
				var ascender = salmon_ascender.instantiate()
				self.add_child(ascender)
				await ascender.ascension_complete
				_load_purgatory()
				$UI.show()
				$UI/KickingMenu/KicksRemainingPurgatory.show()
				
				# go back to regular idle state stuff
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
	$MainDirectionalLight3D.queue_free()
	var sun = _heaven_sun.instantiate()
	add_child(sun)

# replaces all chunks in _current_chunks with the none chunk. 
# do not use if not in purgatory/heaven state.
func _empty_level_chunks() -> void:
	for chunk_z in range(3):
		for chunk_x in range(3):
			_current_chunks[chunk_z][chunk_x].queue_free()
			_current_chunks[chunk_z][chunk_x] = _none_level_segment.instantiate()

# switches to purgatory.
func _load_purgatory() -> void:
	# switch environment
	_load_heaven_environment()
	
	_load_heaven_sun()
	
	# unload level chunks/replace with none
	_empty_level_chunks()
	
	# instantiate purgatory
	purgatory = _purgatory.instantiate()
	self.add_child(purgatory)
	
	# teleport player and rock
	var init_spawn = purgatory.get_spawn_position()
	$Player.position = init_spawn + Vector3(0.0, 0.0, 1.0)
	$Rock.position = init_spawn

# Chooses a new chunk based on current game information. (e.g., kicks_remaining)
func _select_level_segment() -> PackedScene:
	var selected_segment = null
	
	# once kicks remaining goes low enough, pick different segments
	if GameManager.kicks_remaining < GameManager.purgatory_kick_count:
		# purgatory functionality has changed. Now exists as static 3x3 grid with bounds
		#selected_segment = _low_kick_level_segments.pick_random()
		selected_segment = _none_level_segment
	else:
		selected_segment = _level_segments.pick_random()
	
	# fallback
	if selected_segment == null:
		selected_segment = _none_level_segment
	
	return selected_segment
	

## Chooses a new chunk based on current information, adds it to the tree,
## and returns the reference. 
func _instantiate_chunk() -> Node3D:
	var chunk = _select_level_segment().instantiate()
	self.add_child(chunk)
	return chunk

# CHUNK LOADING AND UNLOADING
# Methodology & Process:
# All loading and unloading is done using shift to calculate chunk changes. 
# shift is used to calculate which chunks to unload, which direction to copy from,
# and what ORDER it needs to iterate over the chunks to avoid copy problems.
# This way, all loading and unloading code is written once, and works given any
# direction change. 
# Steps:
# 1. Catch unloading side
# 2. Unload those chunks
# 3. Copy & move the 9 chunks in the shift direction into their new position in _current_chunks
#   a. If any are out of range of _current_chunks, instantiate a new chunk
## Event handler for when the rock moves to a new chunk. 
## Handles all loading, unloading, and internal organization of chunks. 
func _on_grid_position_changed(shift) -> void:
	# reminder: shift is ordered x, z
	# reminder: _current_chunks subscript order is z, x
	
	# used to catch unloading chunks
	var unloaded_chunks := []
	
	# catch unloaded chunks
	for chunk_z in range(3):
		# unload indicators: Transformed to go (1, 0, -1) for comparison against shift.
		# a nonzero z unload indicator means that that chunk will unload if
		# the shift in the z direction matches that indicator. 
		# for example, _current_chunks[2][1] has an unload indicator of z=-1, x=0
		# thus, that chunk (in the positive z direction from the player)
		# will unload if the rock moves in the negative z direction.
		var unload_ind_z = -chunk_z + 1
		for chunk_x in range(3): # 0, 1, 2
			var unload_ind_x = -chunk_x + 1
			if (
				(shift[0] != 0 and shift[0] == unload_ind_x) or
				(shift[1] != 0 and shift[1] == unload_ind_z)
			):
				unloaded_chunks.append(_current_chunks[chunk_z][chunk_x])
	
	# unload old chunks
	for chunk in unloaded_chunks:
		chunk.queue_free()
	
	# determine step ranges (directionality matters)
	# directionality matters, because copy order matters (to not overwrite).
	var z_range := range(0, 3, 1) # default case (no shift in z direction)
	if shift[1]:
		# defines chunk copy-order to be reversed if needed
		# in short, chooses (0,1,2) or (2,1,0)
		z_range = range((1 - shift[1]),(1 + (2 * shift[1])),(shift[1]))
	var x_range := range(0, 3, 1) # default case (no shift in x direction)
	if shift[0]:
		# defines chunk copy-order to be reversed if needed
		x_range = range((1 - shift[0]),(1 + (2 * shift[0])),(shift[0]))
		
	# iterates over _current_chunks, and pulls the new chunk over from the
	# given shift information (diagonals work)
	for chunk_z in z_range:
		for chunk_x in x_range:
			
			# calculate coordinates of the target chunk (the one that needs to be copied)
			var target_chunk_coord_x = chunk_x + shift[0]
			var target_chunk_coord_z = chunk_z + shift[1]
			
			# bounds check
			var in_bounds = true
			if target_chunk_coord_x < 0 or target_chunk_coord_x >= 3:
				in_bounds = false
			if target_chunk_coord_z < 0 or target_chunk_coord_z >= 3:
				in_bounds = false
			
			if in_bounds:
				# if in bounds, copy existing chunk over
				_current_chunks[chunk_z][chunk_x] =\
						_current_chunks[target_chunk_coord_z][target_chunk_coord_x]
			else:
				# otherwise, instantiate a new chunk
				var new_chunk = _instantiate_chunk()
				_current_chunks[chunk_z][chunk_x] = new_chunk
				
				# position the instantiated chunk where it is supposed to appear
				new_chunk.position = Vector3(
						(grid_position[0] + chunk_x - 1) * _grid_x_dimension,
						0.0,
						(grid_position[1] + chunk_z - 1) * _grid_z_dimension)
	
	_current_chunks[1][1].add_collision_to_multimeshes()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	# connect signals
	GameManager.gamestate_update.connect(_on_change_state)
	grid_position_changed.connect(_on_grid_position_changed)
	GameManager.switch_state_to(GameManager.gamestates.IDLE, "Game booted")
	
	# load the first grid
	for z in range(-1, 2, 1):
		for x in range(-1, 2, 1):
			# instantiate
			_current_chunks[z + 1][x + 1] = _instantiate_chunk()
			# position
			_current_chunks[z + 1][x + 1].position =\
					Vector3(x * _grid_x_dimension, 0.0, z * _grid_z_dimension)
	_current_chunks[1][1].add_collision_to_multimeshes()
	
	# Spawn rock and player at a random location in park. 
	var spawn_position = get_spawn()
	var random_y = deg_to_rad(randf_range(0.0, 360.0))
	
	rock.linear_velocity = Vector3.ZERO
	rock.angular_velocity = Vector3.ZERO
	rock.global_position = spawn_position
	
	$Player.current_y_rotation = random_y
	if GameManager.DEBUG:
		print("Spawn direction degrees: ", rad_to_deg($Player.current_y_rotation))
	$Player.global_position = spawn_position + Vector3(0, 0, 3)
	
	# load purgatory if under kick threshold
	if GameManager.kicks_remaining <= GameManager.purgatory_kick_count:
		_load_purgatory()
	
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
	# handle grid position
	_last_grid_position = grid_position.duplicate()
	grid_position[0] = floor( ($Rock.position.x/(_grid_x_dimension)) + (0.5) )
	grid_position[1] = floor( ($Rock.position.z/(_grid_z_dimension)) + (0.5) )
	
	#print("x: ",grid_position[0],", y: ", grid_position[1])
	# if the coordinate has changed
	if (
		_last_grid_position[0] != grid_position[0] or
		_last_grid_position[1] != grid_position[1]
	):
		_current_chunks[1][1].remove_collisions_from_multimeshes()
		
		var shift = Vector2i(grid_position[0] - _last_grid_position[0], grid_position[1]\
				- _last_grid_position[1])
		grid_position_changed.emit(shift)
	
	if player_moving:
		_camera_follow_player()
	
	if panning_camera_active:
		_panning_camera()

func _camera_follow_player() -> void:
	walk_camera.look_at($Player.global_position)

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

# Set the kicks remaining, you need to kick the rock to trigger the change
# so set the number 1 higher than you want
func _console_set_kick(kick: String) -> void:
	GameManager.kicks_remaining = kick.to_int()

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
		if not purgatory:
			print("ERROR: tried to go to purgatory stairs camera but no purgatory was found.")
			return
		
		# kick off animation
		purgatory.stairs_camera_dolly()
		await purgatory.stairs_camera_finished
		
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
