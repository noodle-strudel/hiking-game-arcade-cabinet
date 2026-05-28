#controls everything about the UI, including the contract signing. 
extends Control

#variables
var _start_time := 0.0
var lorem_ipsum_scroll := false
var lorem_ipsum_reset_pos = null
var spinstep = 0

# Called when the node enters the scene tree for the first time.yyyyyyyy
func _ready() -> void:
	#connect signals
	GameManager.decrement_kicks_remaining.connect(_on_update_kicks_remaining)
	GameManager.gamestate_update.connect(_on_change_state)
	#set initial text
	_on_update_kicks_remaining(GameManager.kicks_remaining) #TODO: more elegant solution.
	
	#get start time
	_start_time = Time.get_unix_time_from_system()
	
	#
	lorem_ipsum_reset_pos = $ScoreMenu/LoremIpsum.position
	#
	_clear_ui()
	$IdleMenu.visible = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#rotate the subtitle
	if $IdleMenu.visible:
		var time_delta = Time.get_unix_time_from_system() - _start_time
		var spin = 0.01 * sin(time_delta * 4)
		$IdleMenu/SubtitlePivot.rotation -= spin
	#scroll the game over text
	if lorem_ipsum_scroll:
		$ScoreMenu/LoremIpsum.position.y -= delta * 100
	#hide the contract after it is signed and go to the letter spinner
	if GameManager.state == GameManager.gamestates.CONTRACT and Input.is_action_just_pressed("i_accept"):
		$ContractMenu/Contract.visible = false
		%LetterSpinner.visible = true
	#Handle the letter spinner
	if %LetterSpinner.visible:
		if(spinstep < 2):
			%LetterSpinner/Letter1.text = char((randi() % 26) + 65)
		if(spinstep < 3):
			%LetterSpinner/Letter2.text = char((randi() % 26) + 65)
		if(spinstep < 4):
			%LetterSpinner/Letter3.text = char((randi() % 26) + 65)
		if Input.is_action_just_pressed("i_accept") or Input.is_action_just_pressed("kick"):
			spinstep += 1
			if(spinstep == 5):
				spinstep = 0
				GameManager.switch_state_to(GameManager.gamestates.KICKING, "contract signed")


#called when signal recieved
func _on_update_kicks_remaining(kick_count: int) -> void:
	%KicksRemainingLabel.text = ("KICKS REMAINING: " + str(kick_count))
	
	%KicksRemainingFancy.text = (str(kick_count))

# enable and disable UI elements. cause is mostly used for OOB causes
func _on_change_state(state: GameManager.gamestates, _cause: String) -> void:
	_clear_ui()
	match state:
		GameManager.gamestates.IDLE:
			$IdleMenu.visible = true
		GameManager.gamestates.CONTRACT:
			$ContractMenu.visible = true
		GameManager.gamestates.KICKING:
			$KickingMenu.visible = true
		GameManager.gamestates.ROCK_KICKED:
			$RockKickedMenu.visible = true
		GameManager.gamestates.SCORING:
			_scoring_sequence()


func _scoring_sequence() -> void:
	$ScoreMenu/ScoreElem/RoundScore.text = (str(GameManager.last_score))
	$ScoreMenu.visible = true
	await get_tree().create_timer(1).timeout
	%ScoreElem.visible = true
	await get_tree().create_timer(1).timeout
	%KicksRemainingElem.visible = true
	await get_tree().create_timer(1).timeout
	%KicksRemainingFancy.visible = true
	
	#long, drawn out ending animation #TODO make fancier.
	await get_tree().create_timer(1).timeout
	$ScoreMenu/LoremIpsum.visible = true
	lorem_ipsum_scroll = true
	$ScoreMenu/EpicMusicPlayer.play()

func lorem_ipsum_reset() -> void:
	lorem_ipsum_scroll = false
	$ScoreMenu/LoremIpsum.visible = false
	$ScoreMenu/LoremIpsum.position = lorem_ipsum_reset_pos
	$ScoreMenu/EpicMusicPlayer.stop()

func _clear_ui() -> void:
	#hide each menu
	var menus = get_children()
	for menu in menus:
		menu.visible = false
	#reset for scoring sequence
	%ScoreElem.visible = false
	%KicksRemainingElem.visible = false
	%KicksRemainingFancy.visible = false
	lorem_ipsum_reset()
	#reset for contract sequence
	$ContractMenu/Contract.visible = true
	%LetterSpinner.visible = false
	
