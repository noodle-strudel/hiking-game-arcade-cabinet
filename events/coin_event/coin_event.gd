extends Event

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

#write all necessary code for the event to happen here
func _event_function() -> void:
	print("wohoo I'm a coin")
	$/root/Main/UI/EventElements.visible = true
	$/root/Main/UI/EventElements/CoinSprite.visible = true
	await get_tree().create_timer(0.01).timeout
	$/root/Main/UI/EventElements.visible = true
	await get_tree().create_timer(5).timeout
	$/root/Main/UI/EventElements/CoinSprite.visible = false
	$/root/Main/UI/EventElements.visible = false
	print("don't spend me all in one place!")
	
	#do not remove. Defined in event_base.gd
	_event_cleanup()
