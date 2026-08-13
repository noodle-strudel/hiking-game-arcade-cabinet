class_name Credit extends Label

## float from 0 to 1 indicating how much of the text is visible

# 
func write() -> void:
	#_get_character_length()
	$CreditAnimator.play("write_text")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.visible_ratio = 0.0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
