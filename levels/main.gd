extends Node

#informs the script of what scenes can be instantiated as segments in a level
@onready var _level_segments = [
	preload("res://level_grids/park/park_grid.tscn")
]

@onready var player_camera = $Player/CameraPivot/PlayerCamera
@onready var rock_camera = $Rock/RockCameraPivot/RockCameraArm/RockCamera

# width and breadth of the level segments
const _grid_x_dimension := 2 * 415.146
#const _grid_z_dimension := 2 * 555.845 #seam position as reported by yollaine
const _grid_z_dimension := 2 * 545.1 #estimated actual seam (small gap)

#stores references to the instantiated level grid parts
var _level_grid = [
	[null, null, null] #+x->
	,[null, null, null]
	,[null, null, null]
]	#+z
	# v
#signal emitted from _process when the rock moves to a new "chunk".
#shift is a vector2 with the amount the rock has moved
#e.g., if the rock has moved to the next chunk in the -z direction,
#shift will be (0, -1)
signal grid_position_changed(shift: Vector2i)

#position of the rock within the grid.
var grid_position := [0, 0] #x,z
var _last_grid_position := grid_position.duplicate()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#connect signals
	GameManager.gamestate_update.connect(_change_camera)
	grid_position_changed.connect(_on_grid_position_changed)
	#load the first grid
	for z in range(-1, 2, 1):
		for x in range(-1, 2, 1):
			#instantiate
			_level_grid[z+1][x+1] = _instantiate_chunk()
			#position
			_level_grid[z+1][x+1].position = Vector3(x*_grid_x_dimension, 0.0, z*_grid_z_dimension)

# Camera changes based on gamestate.
func _change_camera(state: GameManager.gamestates, cause: String) -> void:
	match state:
		GameManager.gamestates.IDLE:
			rock_camera.make_current()
		GameManager.gamestates.CONTRACT:
			player_camera.make_current()
		GameManager.gamestates.KICKING:
			player_camera.make_current()
		GameManager.gamestates.ROCK_KICKED:
			rock_camera.make_current()
		GameManager.gamestates.SCORING:
			GameManager.report_distance($Player.global_position.distance_to($Rock.global_position))
			$Rock/RockCameraPivot/RockCameraArm/RockCamera.make_current()
			rock_camera.make_current()
		GameManager.gamestates.ROCK_OOB:
			_handle_oob(cause)
			

func _handle_oob(cause: String) -> void:
	#TODO: freeze the rock's camera in place. aka stop updating the position.
	#INFO: this would be in a function created after May 26.
	#rock_camera.freeze_position() <-- not implemented yet
	
	# reset the rock's position to the player's position
	$Rock.position = $Player.position
	print("OOB: ", cause)
	GameManager.switch_state_to(GameManager.gamestates.KICKING)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#handle grid position
	_last_grid_position = grid_position.duplicate()
	grid_position[0] = floor( ($Rock.position.x/(_grid_x_dimension)) + (0.5) )
	grid_position[1] = floor( ($Rock.position.z/(_grid_z_dimension)) + (0.5) )
	#if the coordinate has changed
	if _last_grid_position[0] != grid_position[0] or _last_grid_position[1] != grid_position[1]:
		var shift = Vector2i(grid_position[0] - _last_grid_position[0], grid_position[1] - _last_grid_position[1])
		grid_position_changed.emit(shift)

#chooses a level segment to add
func _select_level_segment() -> PackedScene:
	print("DEBUG: the return type in _select_level_segment is ", type_string(typeof(_level_segments.pick_random())))
	return _level_segments.pick_random()
	
func _instantiate_chunk() -> Node3D:
	var chunk = _select_level_segment().instantiate()
	self.add_child(chunk)
	print("DEBUG: type of chunk is ", type_string(typeof(chunk)))
	return chunk

#process:
#catch unloading side
#unload
#copy-move 9
# > if any are oob, instantiate in new chunk
#methodology: Everything is done together, and the code works even if you somehow move over the diagonal
#between chunks even in a single frame. 
#it uses the shift value to calculate which chunks to unload, which direction to copy from, 
#and what ORDER it needs to iterate over the chunks to avoid copy problems.
func _on_grid_position_changed(shift) -> void:
	#shift is ordered x, z
	var unloaded_chunks := []
	
	#catch unloaded chunks
	for chunk_z in range(3): #0, 1, 2
		var unload_ind_z = -chunk_z + 1
		for chunk_x in range(3): #0, 1, 2
			var unload_ind_x = -chunk_x + 1
			if (shift[0] != 0 and shift[0] == unload_ind_x) or (shift[1] != 0 and shift[1] == unload_ind_z):
				unloaded_chunks.append(_level_grid[chunk_z][chunk_x])
	
	#unload old chunks
	for chunk in unloaded_chunks:
		chunk.queue_free()
	
	#determine step ranges (directionality matters)
	var z_range := range(0,3,1) #default case
	if shift[1]:
		z_range = range((1-shift[1]),(1+(2*shift[1])),(shift[1]))
	var x_range := range(0,3,1)
	if shift[0]:
		x_range = range((1-shift[0]),(1+(2*shift[0])),(shift[0]))
	for chunk_z in z_range:
		for chunk_x in x_range:
			var target_chunk_coord_x = chunk_x+shift[0]
			var target_chunk_coord_z = chunk_z+shift[1]
			var in_bounds = true
			#bounds check
			if target_chunk_coord_x < 0 or target_chunk_coord_x >= 3:
				in_bounds = false
			if target_chunk_coord_z < 0 or target_chunk_coord_z >=3:
				in_bounds = false
			if in_bounds:
				#if in bounds, copy existing chunk over
				_level_grid[chunk_z][chunk_x] = _level_grid[target_chunk_coord_z][target_chunk_coord_x]
			else:
				#otherwise, instantiate a new chunk
				var new_chunk = _instantiate_chunk()
				_level_grid[chunk_z][chunk_x] = new_chunk
				new_chunk.position = Vector3((grid_position[0] + chunk_x - 1)*_grid_x_dimension, 0.0, (grid_position[1] + chunk_z - 1)*_grid_z_dimension)
				
