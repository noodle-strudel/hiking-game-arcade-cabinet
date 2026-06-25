extends Event

# variable for doing rng to decide which coin to show.
var chance = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	chance = randi() % 100

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

# write all necessary code for the event to happen here
func _event_function() -> void:
	if chance != 99:
		$CoinCanvas.visible = true
	else:
		$TheCoin.visible = true
	await get_tree().create_timer(5).timeout
	$CoinCanvas.visible = false
	$TheCoin.visible = false
	
	#do not remove. Defined in event_base.gd
	_event_cleanup()
