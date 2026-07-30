extends Event

# variable for doing rng to decide which coin to show.
var chance: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

# write all necessary code for the event to happen here
func _event_function() -> void:
	chance = randi_range(0, 99)
	if chance != 27:
		%CoinCanvas.visible = true
		%CoinSprite3D.play("appear")
		$CoinSFXPlayer.play()
		await get_tree().create_timer(0.5).timeout
		%CoinSprite3D.play("spin")
		await get_tree().create_timer(4.5).timeout
		%CoinCanvas.visible = false
	else:
		%Coing.visible = true
		$CoingSFXPlayer.play()
		await get_tree().create_timer(5).timeout
		%Coing.visible = false

	#do not remove. Defined in event_base.gd
	_event_cleanup()
