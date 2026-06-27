@icon("res://events/event_icon.png")
class_name Event extends Node
## Base class for events to occur. Provides a template for making events.
# to use, create a node of type "Event" and define a _event_function() function in its script. 

# signal for when the event has completed
signal event_done

# IF YOU WISH TO CREATE AN EVENT:
# create a script for that extends "Event", and define this function in it. The event_manager will handle
# kicking this off
## Define all event logic in this function for derived scripts.
func _event_function() -> void:
	pass


# should be called as soon as the event is done. Resumes normal gameplay and cleans itself up
## Must be called by deriving scripts at the end of the event.
func _event_cleanup() -> void:
	# unpause the game
	get_tree().paused = false
	
	# rune self from tree
	self.queue_free()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# connect signals
	event_done.connect(_event_cleanup)
	
	# pause the game
	get_tree().paused = true
	
	# kick off script
	_event_function()
	
	# clean up
	#_event_cleanup()
