extends Node

#Saves are made to the Godot appdata folder in app_userdata
const save_location = "user://SaveFile.json"

#Dictionary allows for adding more variables to save easily
var content_to_save : Dictionary = {
	"remaining_kicks" : 0
}

#Loads the save on game startup
func _ready() -> void:
	GameManager.decrement_kicks_remaining.connect(_on_kick_save)
	_load()

#Save function opens the file and writes the data to save to it
func _save() -> void:
	var file = FileAccess.open(save_location, FileAccess.WRITE)
	file.store_var(content_to_save.duplicate())
	file.close()

#If the save file exists this gets the data in there and sets the global kicks remaining
func _load() -> void:
	if FileAccess.file_exists(save_location):
		var file = FileAccess.open(save_location, FileAccess.READ)
		var data = file.get_var()
		file.close()
		
		var save_data = data.duplicate()
		GameManager.kicks_remaining = save_data.remaining_kicks

func _on_kick_save(kicks_remaining:int) -> void:
	content_to_save.remaining_kicks = kicks_remaining
	_save()
