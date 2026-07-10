extends Node

# signal sent when an event finishes (currently unused) #OLD
signal event_clear




# lists of known events. 
# NOTE: if a new kind of event timing is added, it will need to be added
# to event_lists below. 
## events that occur right after the rock is kicked (ex: rock says "ouch!")
const on_kick_events := [
	
]
## events that occur while the rock is traveling (ex: rock wink event)
const during_kick_events := [
	preload("res://events/wink_event/wink_event.tscn")
]
## 
const post_kick_events := [
	preload("res://events/coin_event/coin_event.tscn"),
	preload("res://events/grandma_salmon/grandma_salmon.tscn"),
]
# NOTE: THIS MUST BE UPDATED IF A NEW EVENT TIMING IS ADDED
## Ragged array of all known event lists. 
## Each sub-array is a different event timing. 
@onready var event_lists := [ 
	on_kick_events,
	during_kick_events,
	post_kick_events
]
## List of known event types in order of definition/timing. 
## Informs the meaning of event_indices.
enum event_types {
	ON_KICK_EVENT,
	DURING_KICK_EVENT,
	POST_KICK_EVENT
}


## full concatenated list of all known events. calculated in _ready().
## separate from event_lists, which is a ragged array. 
var known_events := []
## chance of event occuring. ranges from 0.0 to 1.0. 
## TODO: tune this number before release. 
var event_chance := 1.0
## list of indicies indicating where different event types start
## in the full concatenated list known_events. Initialized in _ready().
## Event types are informed by event_types.
var event_indices := []
## total number of known events. 
var total_event_count := 0
## a ceiling for rolling the event value. Initialized in _ready().
var max_event_value := 0 


## a random number that gets rolled for every new kick attempt. 
## value determines if an event occurs, and which one. 
## a value equal to or higher than the total number of events means no event.
var event_value = 0

## rng class used for generating random numbers.
var event_rng = RandomNumberGenerator.new()

# returns a random number for event determination
func _roll_event_rng() -> int:
	return event_rng.randi_range(0, max_event_value)

# state change handler
func _on_change_state(state: GameManager.gamestates, _cause: String) -> void:
	match state:
		GameManager.gamestates.IDLE:
			# reroll event
			event_value = _roll_event_rng()
			
			print("DEBUG: rolled event value ", event_value)
			if event_value < total_event_count:
				print("That means event: " + str(known_events[event_value]))
			else:
				print("That means event: NO_EVENT")
		GameManager.gamestates.CONTRACT:
			pass
		GameManager.gamestates.KICKING:
			pass
		GameManager.gamestates.ROCK_KICKED:
			#if _event_is_of_type("on_kick_event")
			
			
			# TODO: OLD
			var rock_event = null
			
			if event_value == 3:
				rock_event = known_events[event_value].instantiate()
				await get_tree().create_timer(0.4).timeout
				self.add_child(rock_event)
			
			if rock_event:
				await rock_event.tree_exiting
				
		GameManager.gamestates.POSTKICK_EVENT:
			var postkick_event = null
			
			if (event_value != 0 && event_value != 3):
				postkick_event = known_events[event_value].instantiate()
				self.add_child(postkick_event)
				
			if postkick_event:
				await postkick_event.tree_exiting
			
			# Get the player and rock nodes from the main scene.
			var main_scene = get_tree().current_scene
			var player = main_scene.get_node("Player")
			var rock = main_scene.get_node("Rock")
			
			# Caluculate the distance kicked.
			var kick_distance = player.global_position.distance_to(rock.global_position)
			
			# Report the score.
			GameManager.report_score(
				GameManager.current_kick_strength,
				kick_distance
			)
			
			if postkick_event:
				GameManager.switch_state_to(GameManager.gamestates.SCORING, "post kick event finished")
			else:
				GameManager.switch_state_to(GameManager.gamestates.SCORING, "no post kick event")
		GameManager.gamestates.SCORING:
			pass

# NOTE: MUST BE UPDATED IF NEW EVENT TYPE IS ADDED
# returns true if the current event_value is an event of the provided event_type. 
# see event_types definition.
func _event_is_of_type(event_type: event_types) -> bool:	
	match event_type:
			event_types.ON_KICK_EVENT:
				if event_value >= event_indices[0] and event_value < event_indices[1]:
					return true
			event_types.DURING_KICK_EVENT:
				if event_value >= event_indices[1] and event_value < event_indices[2]:
					return true
			event_types.POST_KICK_EVENT:
				if event_value >= event_indices[2] and event_value < total_event_count:
					return true
	return false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# connect signals
	GameManager.gamestate_update.connect(_on_change_state)
	
	# roll rng in case "switch to idle state on game load" code is removed. 
	event_value = _roll_event_rng()
	
	# preprocess known event data
	for event_type_list in event_lists:
		# calculate start index of the current kind of events in known_events
		event_indices.append(known_events.size())
		
		# concatenate all known events into known_events
		known_events += event_type_list
		
		# update total number of events
		total_event_count = known_events.size()
	
	# calculate max roll for event rng
	if event_chance > 0.0 and event_chance <= 1.0:
		max_event_value = (total_event_count / event_chance)
	else:
		max_event_value = total_event_count
	
	print("DEBUG: event indices: " + str(event_indices))
	print("DEBUG: known events: " + str(known_events))
	print("DEBUG: total event count: " + str(total_event_count))
	print("DEBUG: max_event_value: " + str(max_event_value))



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
