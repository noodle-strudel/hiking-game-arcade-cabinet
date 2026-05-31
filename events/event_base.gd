#base class for events to occur. Provides a template for making events
@icon("res://events/event_icon.png")
class_name Event extends Node
#to use, create a node of type "Event" and define a _event_function() function in its script. 

#signal for when the event has completed
signal event_done

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#connect signals
	event_done.connect(_event_cleanup)
	#pause the game
	get_tree().paused = true
	#kick off script
	_event_function()
	#clean up
	#_event_cleanup()

#IF YOU WISH TO CREATE AN EVENT:
#create a script for that extends "Event", and define this function in it. The event_manager will handle
#kicking this off
func _event_function() -> void:
	pass

#should be called as soon as the event is done. Resumes normal gameplay and cleans itself up
func _event_cleanup() -> void:
	#unpause the game
	get_tree().paused = false
	#prune self from tree
	self.queue_free()
