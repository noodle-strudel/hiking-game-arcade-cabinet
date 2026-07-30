extends Grid
class_name HeavenStairsGrid

var purgatory_kicks = GameManager.kicks_remaining - 8000

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	purgatory_kicks = GameManager.kicks_remaining - 8000
	$SignHelper/SubViewport/SignText.text = "Until\nThe Change:\n" + str(purgatory_kicks)
	GameManager.decrement_kicks_remaining.connect(_on_update_kicks_remaining)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_update_kicks_remaining(kick_count: int) -> void:
	purgatory_kicks = kick_count - 8000
	$SignHelper/SubViewport/SignText.text = "Until\nThe Change:\n" + str(purgatory_kicks)
