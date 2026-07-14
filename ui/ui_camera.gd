extends Camera2D

var random_strength := 30.0
var shake_fade := 5.0

var rng = RandomNumberGenerator.new()

var shake_strength := 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if shake_strength > 0:
		shake_strength = lerpf(shake_strength, 0, shake_fade * delta)
		self.offset = random_offset()

func apply_shake(shake_scale: float) -> void:
	shake_strength = random_strength * shake_scale

func random_offset() -> Vector2:
	return Vector2(rng.randf_range(-shake_strength, shake_strength),\
			rng.randf_range(-shake_strength, shake_strength))
