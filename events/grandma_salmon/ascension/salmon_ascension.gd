extends Node3D

# emitted when sequence is done and salmon gone high up
signal ascension_complete

@onready var salmon_helper = $GrandmaSalmonHelper
var look_target = null
var rock = null

func ascension_sequence(go_heaven: bool) -> void:
	# create camera/make current
	$AscensionCamera.make_current()
	
	# animate helper moving to rock
	$SalmonAnimator.play("float_to_rock")
	await $SalmonAnimator.animation_finished
		 
	# camera zoom
	$SalmonAnimator.play("camera_zoom")
	await $SalmonAnimator.animation_finished
	
	# get salmon helper to pick up rock
	var rock_pos_ref = rock.global_position
	salmon_helper.snatch_object(rock.get_path())  
	
	if go_heaven:
		# take rock to bottom of stairs and wait then go up to heaven
		var bottom_of_stairs = $"../WorldGeneration/Purgatory/BottomOfStairs".global_position
		var top_of_stairs = $"../WorldGeneration/Purgatory/TopOfStairs".global_position
		salmon_helper.move_obj(rock_pos_ref, bottom_of_stairs)
		await salmon_helper.on_movement_finished
		rock_pos_ref = rock.global_position
		await get_tree().create_timer(5.0).timeout
		
		# Fight for happiness! plays to motivate the player
		$GrandmaQuoteSFX.play()
		$GrandmaSalmonHelper.play_talk_anim()
		
		$"../WorldGeneration/Purgatory/LevelSegments/HeavenStairsGrid/GateOpenCamera".make_current()
		salmon_helper.move_obj(rock_pos_ref, top_of_stairs, 1)
		await salmon_helper.on_movement_finished
	else:
		# make helper go up while camera looks
		
		# Fight for happiness! plays to motivate the player
		$GrandmaQuoteSFX.play()
		$GrandmaSalmonHelper.play_talk_anim()
		
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
	#_hide_sprite()
	
	# run sequence
	if GameManager.kicks_remaining == GameManager.heaven_kick_count:
		ascension_sequence(true)
	else:
		ascension_sequence(false)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	look_target = rock.position
	if look_target != null and $AscensionCamera.current:
		$AscensionCamera.look_at(look_target)
