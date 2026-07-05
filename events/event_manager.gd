extends Node

# signal sent when an event finishes (currently unused)
signal event_clear

# a random number that gets rolled for every new kick attempt. 
# value determines if an event occurs, and which one. 
# 0 always means no event. 
var event_value = 0
# a ceiling for rolling the event value. 
const max_event_value = 1
#rng class used for generating random numbers
var event_rng = RandomNumberGenerator.new()

# list of events this script can instantiate
var known_events = [
	null,
	preload("res://events/coin_event/coin_event.tscn")
]


# returns a random number for event determination
func _roll_event_rng() -> int:
	return event_rng.randi_range(0, max_event_value)

func _on_change_state(state: GameManager.gamestates, _cause: String) -> void:
	match state:
		GameManager.gamestates.IDLE:
			event_value = _roll_event_rng()
			print("DEBUG: rolled event value ", event_value)
		GameManager.gamestates.CONTRACT:
			pass
		GameManager.gamestates.KICKING:
			pass
		GameManager.gamestates.ROCK_KICKED:
			pass
		GameManager.gamestates.SCORING:
			pass
		GameManager.gamestates.POSTKICK_EVENT:
			var postkick_event = null
			match event_value:
				1: # coin event
					postkick_event = known_events[1].instantiate()
					self.add_child(postkick_event)
			if postkick_event:
				await postkick_event.tree_exiting
				GameManager.switch_state_to(GameManager.gamestates.SCORING, "post kick event finished")
			else:
				GameManager.switch_state_to(GameManager.gamestates.SCORING, "no post kick event")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.gamestate_update.connect(_on_change_state)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
