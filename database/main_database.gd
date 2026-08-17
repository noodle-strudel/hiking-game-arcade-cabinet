extends Node

# must be placed second in order on autoloads,
# below GameManager and above SaveLoads

var kick_db : MariaDBConnector = MariaDBConnector.new()
var ed: Dictionary = {
	"db_password": "12345",
	"db_host": "127.0.0.1",
	"db_name": "kicks_db",
	"db_port": 3306,
	"db_user": "root",
}
var initials : String = ""

# takes the initials passed from the spinner and makes the full string of initials
func set_initials(first, second, third) -> void:
	initials = first + second + third

# gets the amount of rows in the database as that is the number of kicks in there
# returns a variant type to allow returning null or an int
func get_kicks() -> Variant:
	var stmt : String = "SELECT COUNT(*) FROM kicks;"
	var kicks_done : Variant = kick_db.query(stmt)
	if kick_db.last_error != MariaDBConnector.ErrorCode.OK:
		printerr("ERROR %d on SELECT" % [kick_db.last_error])
	else:
		# the query returns an array of dictionaries
		# this address returns the int # of rows/kicks in the database
		return kicks_done[0]["COUNT(*)"]
	return null

# on ready connects to the database and listens for the kick decrement signal
func _ready() -> void:
	GameManager.gamestate_update.connect(_on_score_insert)
	var err : MariaDBConnector.ErrorCode = kick_db.connect_db(ed["db_host"],
			ed["db_port"],
			ed["db_name"],
			ed["db_user"],
			ed["db_password"],
			MariaDBConnector.AUTH_TYPE_MYSQL_NATIVE, false)
	if err != MariaDBConnector.ErrorCode.OK:
		push_error(err)

# When state switches to scoring inserts the score into the database
# Kick number is auto incrementing so doesn't need a value
# Timestamp defaults to current time so also doesn't need a value
# Initials of the kick are now also sent to the database
func _on_score_insert(state : GameManager.gamestates, _cause : String) -> void:
	if state == GameManager.gamestates.SCORING:
		var format_stmt : String = "INSERT INTO kicks (score, initials) VALUES (%d, \"%s\");"
		var stmt : String = format_stmt % [GameManager.last_score, initials]
		var res : Dictionary = kick_db.execute_command(stmt)
		if kick_db.last_error != MariaDBConnector.ErrorCode.OK:
			printerr("ERROR %d on INSERT" % [kick_db.last_error])
		else:
			print("rows affected:", res["affected_rows"])
			print("Last Inserted ID:", res["last_insert_id"])
			$PingTimer.start(3600)

# Sends a ping to the server every hour to keep connection alive
func _on_ping_timer_timeout() -> void:
	kick_db.ping_srvr()
	$PingTimer.start(3600)
