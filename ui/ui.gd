# controls everything about the UI, including the contract signing. 
extends Control

# variables
@onready var game_over_text_scroll_speed : float = (
	(%GameOverText/Bottom.global_position.y + 136) / 50.0
)
@onready var game_over_text_reset_pos : Vector2 = %GameOverText.position
@onready var kicks_remaining_bbcode : String = %KicksRemainingLabel.text
@onready var db_loaded : Node = get_node_or_null("/root/MainDatabase")
@onready var ui_camera := $"../UICamera"
@onready var subtitle : Label = $IdleMenu/SubtitlePivot/Subtitle

const KICKS_REMAINING_EFFECT = "[ghost fade=0.7 span=-10][outline_size=10]"
const KICKS_DONE_EFFECT = "[outline_size=10]"
const OOB_EFFECT_PRE = "[wave amp=100][outline_size=10]"
const OOB_EFFECT_SUF = "[/outline_size][/wave]"

# kickbar power threshold to get a critical kick
@export var crit_threshold: float = 97.0

# length of time to pause the graphics on a critical kick
@export var hitstop_length: float = 0.3

# sfx
@export var rock_scroll: AudioStreamWAV
@export var rock_select: AudioStreamWAV
@export var contract_sign: AudioStreamWAV
@export var initials: AudioStreamWAV
@export var scoring_1: AudioStreamWAV
@export var scoring_2: AudioStreamWAV
@export var scoring_3: AudioStreamWAV
@export var title: AudioStreamWAV

var _start_time := 0.0
var game_over_text_scroll := false
var spinstep := 1
var spin_letters := false
var select_rock := false
var sign_contract := false

# list of rock names, rock name tracker, rock name total
var rock_names = [
	"Digi-Christosphere",
	"Rocksane",
	"Johnrockubgenklhimershmidt",
	"Spherald",
	"Marock",
	"Spheranie"
]
var cur_name = 0
var name_tot = 6

# list of subtitles
var menu_subtitles = [
	"Kick a rock!",
	"The worlds first official\nrock erosion by means\nof podiatric impact\nsimulator!",
	"Kick Rocks!",
	"Stone Punting!",
	"Make this rock ROUND!",
	"You have been\nsummoned to kick\nthis sacred stone...",
	"Plabolnbar!"
]

func hide_kicking_ui():
	$KickingMenu.hide()

func game_over_text_reset() -> void:
	game_over_text_scroll = false
	%GameOverText.hide()
	%GameOverText.position = game_over_text_reset_pos

# Picks a randome sibtitle for the menu.
func _get_random_subtitle() -> void:
	subtitle.text = menu_subtitles.pick_random()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# connect signals
	GameManager.decrement_kicks_remaining.connect(_on_update_kicks_remaining)
	GameManager.gamestate_update.connect(_on_change_state)
	# need to wait for parent to be ready to avoid race condition
	await $"..".ready
	$"..".rock_followcam_activated.connect(hide_kicking_ui)
	# set initial text
	_on_update_kicks_remaining(GameManager.kicks_remaining) #TODO: more elegant solution.
	
	_clear_ui()
	$IdleMenu.show()
	_get_random_subtitle()
	%IdleAnimationPlayer.play("swing_subtitle")
	if (
		GameManager.kicks_remaining < GameManager.heaven_kick_count and
		GameManager.kicks_remaining > GameManager.purgatory_kick_count
	):
		$KickingMenu/PurgKicksRemainingContainer.show()
	else:
		$KickingMenu/PurgKicksRemainingContainer.hide()
		


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# scroll the game over text
	if game_over_text_scroll:
		%GameOverText.position.y -= delta * game_over_text_scroll_speed
	
	# Handle the letter spinner
	elif spin_letters:
		match spinstep:
			1:
				%Letter1.text = _random_uppercase()
				%Letter2.text = _random_uppercase()
				%Letter3.text = _random_uppercase()
			2:
				%Letter2.text = _random_uppercase()
				%Letter3.text = _random_uppercase()
			3:
				%Letter3.text = _random_uppercase()
		if (
			Input.is_action_just_pressed("confirm") and
			!GameManager.console_open
		):
			spinstep += 1
			$MenuSFX.set_stream(initials)
			$MenuSFX.play()
			if spinstep == 4:
				# checks to see if the db script is loaded
				# and sends the initials to the database to be inserted
				if is_instance_valid(db_loaded):
					db_loaded.set_initials(%Letter1.text, %Letter2.text, %Letter3.text)
				
				# wait 2 seconds before continuing to rock select
				await get_tree().create_timer(2).timeout
				spin_letters = false
				spinstep = 1
				%LetterSpinner.visible = false
				$RockSelect.visible = true
				select_rock = true
			
			# rock select
	elif select_rock:
		# left and right make new name
		if !GameManager.console_open:
			if Input.is_action_just_pressed("joystick_left"):
				cur_name -= 1
				if cur_name < 0:
					cur_name = name_tot - 1
				$RockSelect/RockName.text = rock_names[cur_name]
				$MenuSFX.set_stream(rock_scroll)
				$MenuSFX.play()
			elif Input.is_action_just_pressed("joystick_right"):
				cur_name += 1
				if cur_name >= name_tot:
					cur_name = 0
				$RockSelect/RockName.text = rock_names[cur_name]
				$MenuSFX.set_stream(rock_scroll)
				$MenuSFX.play()
				
			# enter continues to gameplay
			elif Input.is_action_just_pressed("confirm"):
				$RockSelect.visible = false
				$MenuSFX.set_stream(rock_select)
				$MenuSFX.play()
				await get_tree().create_timer(0.1).timeout
				GameManager.switch_state_to(GameManager.gamestates.KICKING,\
				"contract signed")
				select_rock = false
	else:
		# hide the contract after it is signed and go to the letter spinner
		if (
			GameManager.state == GameManager.gamestates.CONTRACT and
			Input.is_action_just_pressed("confirm") and
			!GameManager.console_open
		):
			if sign_contract:
				$MenuSFX.set_stream(contract_sign)
				$MenuSFX.play()
				$ContractMenu/ContractContainer.hide()
				%LetterSpinner.show()
				sign_contract = false
				spin_letters = true
			else:
				# when pressing any button at first (when debugging you'll have
				# to press confirm twice when going into contract
				sign_contract = true


# used for letter spinner. Returns a random uppercase character.
func _random_uppercase() -> String:
	return char((randi() % 26) + 65)

# called when signal recieved
func _on_update_kicks_remaining(kick_count: int) -> void:
	var kicks_remaining_str := "KICKS REMAINING: "
	var purgatory_kicks = kick_count - GameManager.heaven_kick_count
	var kicks_done = GameManager.STARTING_KICKS - kick_count
	%KicksRemainingNumLabel.text = KICKS_REMAINING_EFFECT + str(kick_count)
	%KicksDoneNumLabel.text = KICKS_DONE_EFFECT + str(kicks_done)
	%KicksRemainingGameplay.text = kicks_remaining_str
	%KicksRemainingGameplayNum.text = str(kick_count)
	%KicksRemainingFancy.text = str(kick_count)
	%KicksRemainingPurgatory.text = "UNTIL HEAVEN: " + str(purgatory_kicks)


# enable and disable UI elements. cause is mostly used for OOB causes
func _on_change_state(state: GameManager.gamestates, cause: String) -> void:
	_clear_ui()
	%EndPoemVoice.stop()
	match state:
		GameManager.gamestates.IDLE:
			GameManager.critical_kick = false
			# reset state variables
			spin_letters = false
			select_rock = false
			sign_contract = false

			$IdleMenu.show()
			_get_random_subtitle()
			%IdleAnimationPlayer.play("swing_subtitle")
		GameManager.gamestates.CONTRACT:
			$MenuSFX.set_stream(title)
			$MenuSFX.play()
			$ContractMenu.show()
			$ContractMenu/ContractContainer.show()
		GameManager.gamestates.KICKING:
			$KickingMenu.show()
			%KickbarAnimator.play("RESET")
			%KickbarAnimator.play("power_modulate")
		GameManager.gamestates.ROCK_KICKED:
			%KickbarAnimator.pause()
			$KickingMenu.show()
			ui_camera.apply_shake(0.1)
			
			if %Kickbar.value >= crit_threshold:
				if GameManager.DEBUG:
					print("critical kick!")
				%Kickbar.value = 200.0
				GameManager.critical_kick = true
				
				# add juice
				# critical kick sound
				$"../Rock".play_kick(true)
				ui_camera.apply_shake(2)
				get_tree().paused = true
				await get_tree().create_timer(hitstop_length).timeout
				get_tree().paused = false
				
				# wow sound effect
				await get_tree().create_timer(0.7).timeout
				$KickingMenu/WowPlayer.play()
			else:
				$"../Rock".play_kick(false) # normal kick sound
			
		GameManager.gamestates.SCORING:
			_scoring_sequence()
			
			# didn't really know where else to put this so i'll put it here
			# turn off until heaven kicks when in heaven
			if GameManager.kicks_remaining <= GameManager.purgatory_kick_count:
				$KickingMenu/PurgKicksRemainingContainer.hide()
		GameManager.gamestates.ROCK_OOB:
			$OOBCenterContainer.show()
			%OOBText.text = OOB_EFFECT_PRE + cause + OOB_EFFECT_SUF
			var tween = get_tree().create_tween()
			tween.tween_property(
				%OOBText,
				"modulate",
				Color.WHITE,
				1
			).set_trans(Tween.TRANS_LINEAR)
			await get_tree().create_timer(4).timeout
			tween = get_tree().create_tween()
			tween.tween_property(
				%OOBText,
				"modulate",
				Color.TRANSPARENT,
				1
			).set_trans(Tween.TRANS_LINEAR)
			await get_tree().create_timer(1.5).timeout
			$OOBCenterContainer.hide()
		GameManager.gamestates.ROCK_PERFECTED:
			if GameManager.DEBUG:
				print("UI: Show text that pops up when kicks_remaining <= 0")
			await get_tree().create_timer(8).timeout
			$RockPerfectedMenu.show()
			$ScoreMenu.show()
			%CreditsAnimator.play("credits")

# Scoring sequence function
func _scoring_sequence() -> void:
	
	# Sets the score and then brings up score screen elements, delays for pacing
	$ScoreMenu/ScoreElem/RoundScore.text = (str(GameManager.last_score))
	$ScoreMenu.show()
	await get_tree().create_timer(1).timeout
	%ScoreElem.show()
	$MenuSFX.set_stream(scoring_1)
	$MenuSFX.play()
	await get_tree().create_timer(1).timeout
	%KicksRemainingElem.show()
	$MenuSFX.set_stream(scoring_2)
	$MenuSFX.play()
	await get_tree().create_timer(1).timeout
	%KicksRemainingFancy.show()
	$MenuSFX.set_stream(scoring_3)
	$MenuSFX.play()
	
	await get_tree().create_timer(1).timeout
	
	if GameManager.kicks_remaining > 0:
		# long, drawn out ending animation
		%GameOverText.show()
		game_over_text_scroll = true
		AudioManager.play_track(AudioManager.game_over_music)
		%CreditsAnimator.play("credits")
		await get_tree().create_timer(38).timeout
	
		# duck music for voice
		var music_bus_idx = AudioServer.get_bus_index("Music")
		var music_bus_vol = AudioServer.get_bus_volume_db(music_bus_idx)
		var set_music_volume = func(volume_db: float) -> void:
			AudioServer.set_bus_volume_db(music_bus_idx, volume_db)
	
		var tween_duck = create_tween()
		tween_duck.tween_method(
			set_music_volume,
			music_bus_vol,
			music_bus_vol - 9,
			0.4
		)
	
		await get_tree().create_timer(0.4).timeout
		%EndPoemVoice.play()
		await get_tree().create_timer(9).timeout

	await get_tree().create_timer(1).timeout
	
	# Condition so the state switching and music cutting on the timers only happens
	# if the game is still in the scoring state
	if GameManager.state == GameManager.gamestates.SCORING:
		AudioManager.fade_out_music()
		
		if GameManager.kicks_remaining > 0:
			GameManager.switch_state_to(
				GameManager.gamestates.MOVE_TO_ROCK,
				"scoring sequence finished"
			)
		else:
			GameManager.switch_state_to(
				GameManager.gamestates.ROCK_PERFECTED,
				"0 kicks achieved!"
			)


func _clear_ui() -> void:
	
	# hide each menu
	var menus = get_children()
	for menu in menus:
		if menu != $MenuSFX:
			menu.hide()
	
	# reset for scoring sequence
	%ScoreElem.hide()
	%KicksRemainingElem.hide()
	%KicksRemainingFancy.hide()
	game_over_text_reset()
	
	# reset for contract sequence 
	%Contract.show()
	%LetterSpinner.hide()
