class_name Credit extends Label

## float from 0 to 1 indicating how much of the text is visible
@export var progress := 0.0
var character_count : int = 0


# 
func write() -> void:
	#_get_character_length()
	$CreditAnimator.play("write_text")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	character_count = _get_character_length()
	self.visible_characters = 0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	self.visible_characters = int(progress * character_count)

func _get_character_length() -> int:
	return self.text.length()
