extends Node3D

# emitted when sequence is done and salmon gone high up
signal ascension_complete

var look_target = null
var rock = null
@onready var salmon_helper = $GrandmaSalmonHelper

func ascension_sequence() -> void:
	# create camera/make current
	$AscensionCamera.make_current()
	
	# animate helper moving to rock
	$SalmonAnimator.play("float_to_rock")
	await $SalmonAnimator.animation_finished
	
	# get salmon helper to pick up rock
	var rock_pos_ref = rock.global_position
	salmon_helper.snatch_object(rock.get_path())  
	
	# make helper go up while camera looks
	salmon_helper.move_obj(rock_pos_ref, rock_pos_ref + Vector3(0.0, 100.0, 0.0))
	await salmon_helper.on_movement_finished
	
	# drop rock
	rock.linear_velocity = Vector3.ZERO
	rock.global_position = salmon_helper.get_snatcher_pos()
	salmon_helper.release_object()
	salmon_helper.queue_free()
	
	ascension_complete.emit()
	self.queue_free()

func _hide_sprite() -> void:
	salmon_helper.get_node("GrandmaSalmonSprite").hide()
	salmon_helper.get_node("GrandmaSalmon3D").hide()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# check rock, player, etc exist
	rock = $"../Rock"
	if rock == null:
		print("ERROR: SalmonAscension initiated but no rock found as sibling.")
		self.queue_free()
		
	# position self
	self.position = rock.position
	
	# set look target
	look_target = rock.position
	
	# DEBUG not displaying correctly. temp workaround
	_hide_sprite()
	
	# run sequence
	ascension_sequence()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	look_target = rock.position
	if look_target != null and $AscensionCamera.current:
		$AscensionCamera.look_at(look_target)
