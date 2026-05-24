extends Node

#informs the script of what scenes can be instantiated as segments in a level
@onready var _level_segments = [
	preload("res://level_grids/park/park_grid.tscn")
]

const _grid_x_dimension = 2 * 415.146
#const _grid_z_dimension = 2 * 555.845 #seam position as reported by yollaine
const _grid_z_dimension = 2 * 545.1 #estimated actual seam (small gap)


#stores references to the instantiated level grid parts
var _level_grid = [
	[null, null, null] #+x->
	,[null, null, null]
	,[null, null, null]
]	#+z
	# v

#position of the rock within the grid. 
var grid_position = [0, 0] #x,z

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.gamestate_update.connect(_change_camera)
	
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
			$Rock/RockCameraPivot/RockCameraArm/RockCamera.make_current()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#thoughts: add by origin offset, divide by square size, floor, etc
	grid_position[0] = floor( ($Rock.position.x/(_grid_x_dimension)) + (0.5) )
	grid_position[1] = floor( ($Rock.position.z/(_grid_z_dimension)) + (0.5) )
	print(grid_position)

#chooses a level segment to add
func _select_level_segment():
	return _level_segments.pick_random()
