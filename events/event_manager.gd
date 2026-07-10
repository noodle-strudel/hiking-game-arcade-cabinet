extends Node

# signal sent when post kick event finishes 
signal on_postkick_event_done

# a ceiling for rolling the event value. 
const max_event_value = 3

# list of events this script can instantiate
var known_events = [
	null,
	preload("res://events/coin_event/coin_event.tscn"),
	preload("res://events/grandma_salmon/grandma_salmon.tscn"),
	preload("res://events/wink_event/wink_event.tscn"),
]

# a random number that gets rolled for every new kick attempt. 
# value determines if an event occurs, and which one. 
# 0 always means no event. 
var event_value = 0

# rng class used for generating random numbers
var event_rng = RandomNumberGenerator.new()

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
			var rock_event = null
			
			if event_value == 3:
				rock_event = known_events[event_value].instantiate()
				await get_tree().create_timer(0.4).timeout
				self.add_child(rock_event)
			
			if rock_event:
				await rock_event.tree_exiting
				
		GameManager.gamestates.SCORING:
			pass
		GameManager.gamestates.POSTKICK_EVENT:
			var postkick_event = null
			
			if (event_value != 0 && event_value != 3):
				postkick_event = known_events[event_value].instantiate()
				self.add_child(postkick_event)
				
			if postkick_event:
				await postkick_event.tree_exiting
				on_postkick_event_done.emit()
			else:
				on_postkick_event_done.emit()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.gamestate_update.connect(_on_change_state)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
