extends CenterContainer

var display_seconds : float = 10.0

func display_credits() -> void:
	#self.show()
	var credit_list = _get_credit_list()
	for credit in credit_list:
		credit.write() 
	get_tree().create_timer(display_seconds).timeout
	#self.hide()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _get_credit_list() -> Array:
	var result : = []
	for credit in $VBoxContainer.get_children():
		if credit is Credit:
			result.append(credit)
	return result
