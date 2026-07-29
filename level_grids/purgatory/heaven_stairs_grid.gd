extends Grid
class_name HeavenStairsGrid


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$SignHelper/SubViewport/SignText.text = "Until\nThe Change:\n" \
	+ str($"/root/GameManager".kicks_remaining - 8000)
