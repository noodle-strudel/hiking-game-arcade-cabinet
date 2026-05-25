extends Control

var active = false
var direction = 0 # 0 for left, 1 for right

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	# moving the kickbar indicator
	if(active):
		if(direction == 0):
			$KickbarInd.move_local_x(-delta * 75)
			if($KickbarInd.position.x <= -115):
				direction = 1
		else:
			$KickbarInd.move_local_x(delta * 75)
			if($KickbarInd.position.x >= 80):
				direction = 0

# Function to change wether the indicator should be moving or not.
func _indicator_activity_change():
	if(not active):
		$KickbarInd.position.x = 0
		active = true
	else:
		active = false
