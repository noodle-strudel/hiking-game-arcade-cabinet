extends Node

#must be made global before release
#or we discuss some other way to have it enter the scene tree
#only before release as it will cause errors if MariaDB server isn't installed

var kick_db : MariaDBConnector = MariaDBConnector.new()
var ed: Dictionary = {
	"db_password": "12345",
	"db_host": "127.0.0.1",
	"db_name": "kicks_db",
	"db_port": 3306,
	"db_user": "root",
}

#on ready connects to the datababse and listens for the kick decrement signal
func _ready() -> void:
	GameManager.decrement_kicks_remaining.connect(_on_kick_insert)
	var err : MariaDBConnector.ErrorCode = kick_db.connect_db(ed["db_host"],
			ed["db_port"],
			ed["db_name"],
			ed["db_user"],
			ed["db_password"],
			MariaDBConnector.AUTH_TYPE_MYSQL_NATIVE, false)
	if err != MariaDBConnector.ErrorCode.OK:
		push_error(err)
		return

#When kicks are decremented inserts the score into the database
#Kick number is auto incrementing so doesn't need a value
#Timestamp defaults to current time so also doesn't need a value
func _on_kick_insert(kicks_remaining: int) -> void:
	var stmt : String = "INSERT INTO kicks (score) VALUES (%d);" % GameManager.last_score
	var res : Dictionary = kick_db.execute_command(stmt)
	if kick_db.last_error != MariaDBConnector.ErrorCode.OK:
		printerr("ERROR %d on INSERT" % [kick_db.last_error])
	else:
		print("rows affected:", res["affected_rows"])
		print("Last Inserted ID:", res["last_insert_id"])
