extends Node

#informs the script of what scenes can be instantiated as segments in a level
@onready var _level_segments = [
	preload("res://level_grids/park/park_grid.tscn")
]

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
var _last_grid_position := grid_position

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#connect signals
	GameManager.gamestate_update.connect(_change_camera)
	grid_position_changed.connect(_on_grid_position_changed)
	#load the first grid
	for z in range(-1, 2, 1):
		for x in range(-1, 2, 1):
			#instantiate
			_level_grid[z+1][x+1] = _select_level_segment().instantiate()
			#parent
			self.add_child(_level_grid[z+1][x+1])
			#position TODO
			_level_grid[z+1][x+1].position = Vector3(z*_grid_x_dimension, 0.0, x*_grid_z_dimension)

# Camera changes based on gamestate.
func _change_camera(state: GameManager.gamestates) -> void:
	match state:
		GameManager.gamestates.IDLE:
			$Rock/RockCameraPivot/RockCameraArm/RockCamera.make_current()
		GameManager.gamestates.CONTRACT:
			$Player/CameraPivot/PlayerCamera.make_current()
		GameManager.gamestates.KICKING:
			$Player/CameraPivot/PlayerCamera.make_current()
		GameManager.gamestates.ROCK_KICKED:
			$Rock/RockCameraPivot/RockCameraArm/RockCamera.make_current()
		GameManager.gamestates.SCORING:
			GameManager.report_distance($Player.global_position.distance_to($Rock.global_position))
			$Rock/RockCameraPivot/RockCameraArm/RockCamera.make_current()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#handle grid position
	_last_grid_position = grid_position
	grid_position[0] = floor( ($Rock.position.x/(_grid_x_dimension)) + (0.5) )
	grid_position[1] = floor( ($Rock.position.z/(_grid_z_dimension)) + (0.5) )
	#if the coordinate has changed
	if _last_grid_position[0] != grid_position[0] or _last_grid_position[1] != grid_position[1]:
		var shift = Vector2i(grid_position[0] - _last_grid_position[0], grid_position[1] - _last_grid_position[1])
		grid_position_changed.emit()

#chooses a level segment to add
func _select_level_segment():
	return _level_segments.pick_random()
	
func _load_chunks() -> void:
	pass

#process:
#catch unloading side
#move 6
#instantiate in new chunks
func _on_grid_position_changed(shift) -> void:
	#x, z
	#x direction
	if shift[0] == 1:
		pass
	elif shift[0] == -1:
		pass
	#z direction
	if shift[1] == 1:
		pass
	elif shift[1] == -1:
		pass
