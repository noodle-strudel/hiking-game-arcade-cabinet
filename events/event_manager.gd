extends Node
# NOTE: If you are adding a new event, simply design the event and add it to the
# appropriate list of known events. For example, if you wanted to add a new
# post-kick event, add it to the post_kick_events array. 

# NOTE: If you are adding an event that has different timing to an existing
# type already covered by this script, you must update code in a few places. 
# 1. Add a new array for the event type, like on_kick_events. 
# 2. Add that array to event_lists IN THE CORRECT SEQUENCE ORDER. 
#    for example, if you added a contract event timing it would go first. 
# 3. Update the event_types enum, again making sure it is in the same correct
#    sequence order.
# 4. Update the _event_is_of_type() function. Add the match case in the correct
#    place, and update the indices accordingly. 
#    The last bounds in the sequence is total_event_count. 
#    For example, if you were to add a new event timing between ON_KICK and
#    DURING_KICK, you would need to update all subsequent indices in the if statements. 
#    Hopefully, the pattern should be intuitive.
# 5. Lastly, add code to run the event type in the _on_change_state handler. 
#    Follow the examples. 
#    If you are experiencing a timing issue, try waiting for the event_clear signal
#    after calling _run_event(). 
# Feel free to ping me if you need help! -Melody


# signal sent when an event finishes 
signal event_clear

# lists of known events. 
## events that occur right after the rock is kicked (ex: rock says "ouch!")
const on_kick_events := [
	
]
## events that occur while the rock is traveling (ex: rock wink event)
const during_kick_events := [
	preload("res://events/wink_event/wink_event.tscn")
]
## events that occur just after the rock has come to a rest (ex: coin event)
const post_kick_events := [
	preload("res://events/coin_event/coin_event.tscn"),
	preload("res://events/grandma_salmon/grandma_salmon.tscn"),
]
# NOTE: MUST BE UPDATED IF NEW EVENT TYPE IS ADDED
## Ragged array of all known event lists. 
## Each sub-array is a different event timing. 
@onready var event_lists := [ 
	on_kick_events,
	during_kick_events,
	post_kick_events
]
# NOTE: MUST BE UPDATED IF NEW EVENT TYPE IS ADDED
## List of known event types in order of definition/timing. 
## Informs the meaning of event_indices.
enum event_types {
	ON_KICK,
	DURING_KICK,
	POST_KICK
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
			# handle on kick events
			if _event_is_of_type(event_types.ON_KICK):
				_run_event()
			
			await get_tree().create_timer(0.4).timeout
			# handle during kick events
			if _event_is_of_type(event_types.DURING_KICK):
				_run_event()
			
		GameManager.gamestates.POSTKICK_EVENT:
			if _event_is_of_type(event_types.POST_KICK):
				_run_event()
				# this line is needed because the compiler hates me.
				# fixes timing issue. 
				await event_clear
			
			# Get the player and rock nodes from the main scene.
			var main_scene = get_tree().current_scene
			var player = main_scene.get_node("Player")
			var rock = main_scene.get_node("Rock")
			
			# Calculate the distance kicked.
			var kick_distance = player.global_position.distance_to(rock.global_position)
			
			# Report the score.
			GameManager.report_score(
				GameManager.current_kick_strength,
				kick_distance
			)
			
			# post kick event handling done  
			GameManager.switch_state_to(GameManager.gamestates.SCORING, "post kick event handler finished")
			
		GameManager.gamestates.SCORING:
			pass

# NOTE: MUST BE UPDATED IF NEW EVENT TYPE IS ADDED
# returns true if the current event_value is an event of the provided event_type. 
# see event_types definition.
func _event_is_of_type(event_type: event_types) -> bool:	
	match event_type:
			event_types.ON_KICK:
				if event_value >= event_indices[0] and event_value < event_indices[1]:
					return true
			event_types.DURING_KICK:
				if event_value >= event_indices[1] and event_value < event_indices[2]:
					return true
			event_types.POST_KICK:
				if event_value >= event_indices[2] and event_value < total_event_count:
					return true
	return false 

# called from the state handler, where the code for determining event timing lives. 
# instantiates the rolled event. 
func _run_event() -> void:
	var event = known_events[event_value].instantiate()
	self.add_child(event)
	await event.event_finished
	event_clear.emit()

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
	
	#print("DEBUG: event indices: " + str(event_indices))
	#print("DEBUG: known events: " + str(known_events))
	#print("DEBUG: total event count: " + str(total_event_count))
	#print("DEBUG: max_event_value: " + str(max_event_value))



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
