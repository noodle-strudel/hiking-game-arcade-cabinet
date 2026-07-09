extends Node

# Saves are made to the Godot appdata folder in app_userdata
const save_location = "user://SaveFile.json"

# This variable allows the script to handle what to do when the db is loaded or not
@onready var db_loaded : Node = get_node_or_null("/root/MainDatabase")
# Dictionary allows for adding more variables to save easily
var content_to_save : Dictionary = {
	"remaining_kicks" : 0
}

# Loads the save on game startup
func _ready() -> void:
	GameManager.decrement_kicks_remaining.connect(_on_kick_save)
	_load()

# Save function opens the file and writes the data to save to it
func _save() -> void:
	var file = FileAccess.open(save_location, FileAccess.WRITE)
	file.store_var(content_to_save.duplicate())
	file.close()

# If the save file exists this gets the data in there and sets the global kicks remaining
func _load() -> void:
	if FileAccess.file_exists(save_location):
		var file = FileAccess.open(save_location, FileAccess.READ)
		var data = file.get_var()
		file.close()
		
		var save_data = data.duplicate()
		# if the database is loaded the kicks remaining is loaded to match the database
		if is_instance_valid(db_loaded) and db_loaded.kick_db.is_connected_db:
			var kicks_done : int = db_loaded.get_kicks()
			GameManager.kicks_remaining = 1000000 - kicks_done
		else:
			GameManager.kicks_remaining = save_data.remaining_kicks

func _on_kick_save(kicks_remaining:int) -> void:
	content_to_save.remaining_kicks = kicks_remaining
	_save()
