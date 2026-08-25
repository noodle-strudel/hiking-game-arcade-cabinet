extends Node

# signal emitted from _process when the rock moves to a new "chunk".
# shift is a vector2 with the amount the rock has moved
# e.g., 
## Emitted when the rock moves to a new chunk. 
## ex: if the rock has moved to the next chunk in the -z direction,
## shift will be (0, -1)
signal grid_position_changed(shift: Vector2i)
signal on_load_heaven
signal on_load_purgatory

## List of scenes that can be instantiated as chunks
@onready var _level_segments = [
	preload("res://level_grids/park/park_grid.tscn"),
	preload("res://level_grids/city/city_grid.tscn"),
]

## List of scenes that can be instantiated after 8000 kicks remaining
@onready var _heaven_level_segments = [
	preload("res://level_grids/heaven/heaven_grid.tscn"),
	
]

@onready var _none_level_segment = preload("res://level_grids/none/none_level_grid.tscn")
@onready var _purgatory = preload("res://levels/purgatory/purgatory.tscn")
@onready var lintball := preload("res://events/lintball/lintball.tscn")
@onready var largest_pants := preload("res://events/largest_pants/pants.tscn")
@onready var rock := $Rock

## The 2d array of currently loaded chunks, centered on the rock.
## Stores references to instantiated chunks. 
## Ordered as z, x. [1,1] is the current center of the grid.
var _current_chunks = [
	[null, null, null], # +x->
	[null, null, null],
	[null, null, null]
]	# +z
	# v

## Current chunk displacement since game was instantiated. Ordered x, z. 
var grid_position := [0, 0] # x,z
var _last_grid_position := grid_position.duplicate()

# holds the reference to purgatory level, when instantiated
var purgatory = null

# Width and breadth of the level segments
const _grid_x_dimension := 2 * 250.0
const _grid_z_dimension := 2 * 250.0 

func get_spawn() -> Vector3:
	if purgatory:
		return purgatory.get_spawn_position()
	var grid: Grid = _current_chunks[1][1]
	var spawn_position: Vector3 = grid.get_spawn_position()
	return spawn_position

func get_center_grid() -> Grid:
	return _current_chunks[1][1]

# replaces all chunks in _current_chunks with the none chunk. 
# do not use if not in purgatory/heaven state.
func _empty_level_chunks() -> void:
	for chunk_z in range(3):
		for chunk_x in range(3):
			_current_chunks[chunk_z][chunk_x].queue_free()
			_current_chunks[chunk_z][chunk_x] = _none_level_segment.instantiate()

# Chooses a new chunk based on current game information. (e.g., kicks_remaining)
func _select_level_segment() -> PackedScene:
	var selected_segment = null
	
	# once kicks remaining goes low enough, pick different segments
	if GameManager.kicks_remaining <= GameManager.heaven_kick_count:
		selected_segment = _heaven_level_segments.pick_random()
	elif GameManager.kicks_remaining < GameManager.purgatory_kick_count:
		# purgatory functionality has changed. Now exists as static 3x3 grid with bounds
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

# switches to purgatory.
func _load_purgatory() -> void:
	# unload level chunks/replace with none
	_empty_level_chunks()
	
	# instantiate purgatory
	purgatory = _purgatory.instantiate()
	self.add_child(purgatory)
	emit_signal("on_load_purgatory")


func _load_heaven() -> void:
	# spawn in the initial heaven grid after being taken up by grandma salmon
	# frees purgatory first _empty_level_chunks does not work for purgatory
	if purgatory:
		purgatory.queue_free()

	for z in range(-1, 2, 1):
		for x in range(-1, 2, 1):
			# instantiate
			_current_chunks[z + 1][x + 1] = _instantiate_chunk()
			# position
			_current_chunks[z + 1][x + 1].position =\
					Vector3(x * _grid_x_dimension, 0.0, z * _grid_z_dimension)
	_current_chunks[1][1].add_collision_to_multimeshes()
	await get_tree().process_frame
	emit_signal("on_load_heaven")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	grid_position_changed.connect(_on_grid_position_changed)
	
	# load purgatory if under kick threshold
	if GameManager.kicks_remaining <= GameManager.heaven_kick_count:
		_load_heaven()
	elif GameManager.kicks_remaining <= GameManager.purgatory_kick_count:
		_load_purgatory()
	else:
		# load the first grid
		for z in range(-1, 2, 1):
			for x in range(-1, 2, 1):
				# instantiate
				_current_chunks[z + 1][x + 1] = _instantiate_chunk()
				# position
				_current_chunks[z + 1][x + 1].position =\
						Vector3(x * _grid_x_dimension, 0.0, z * _grid_z_dimension)
	_current_chunks[1][1].add_collision_to_multimeshes()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# handle grid position
	_last_grid_position = grid_position.duplicate()
	grid_position[0] = floor( ($"../Rock".position.x/(_grid_x_dimension)) + (0.5) )
	grid_position[1] = floor( ($"../Rock".position.z/(_grid_z_dimension)) + (0.5) )
	
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
	
	# Try to spawn the lint ball or largest pants on the current grid
	var rand = randi_range(1, 2)
	if rand == 1:
		_lint_ball_spawn_check(_current_chunks[1][1])
	else:
		_largest_pants_spawn_check(_current_chunks[1][1])

func _lint_ball_spawn_check(current_chunk: Node3D) -> void:
	# get random position for the ball to spawn
	var spawnpoint: Vector3 = current_chunk.get_spawn_position()
	
	# add the ball as a child of the current chunk
	# (so it will be culled if left behind)
	var ball := lintball.instantiate()
	current_chunk.add_child(ball)
	
	# position the ball
	ball.position = spawnpoint + Vector3(0.0, 10.0, 0.0)
	
func _largest_pants_spawn_check(current_chunk: Node3D) -> void:
	# get random position for the pants to spawn
	var spawnpoint: Vector3 = current_chunk.get_spawn_position()
	
	# add the pants as a child of the current chunk
	# (so it will be culled if left behind)
	var pants := largest_pants.instantiate()
	current_chunk.add_child(pants)
	
	# position the pants 
	pants.position = spawnpoint + Vector3(0.0, 10.0, 0.0)
