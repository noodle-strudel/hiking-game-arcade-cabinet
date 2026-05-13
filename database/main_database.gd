extends Node

var kick_db : MariaDBConnector
var db_dictionary : Dictionary = {
	"db_host" : "127.0.0.1",
	"db_name" : "kicks_db",
	"db_port" : 3306,
	"db_user" : "temp username",
	"db_password" : "temp password"
}

#_ready isn't set in stone if there is a better func to use,
#it is just what was used in the example.
func _ready() -> void:
	
	var err : MariaDBConnector.ErrorCode = kick_db.connect_db(db_dictionary["db_host"],
			db_dictionary["db_port"],
			db_dictionary["db_name"],
			db_dictionary["db_user"],
			db_dictionary["db_password"])
	if err != MariaDBConnector.ErrorCode.OK:
		push_error(err)
		return
