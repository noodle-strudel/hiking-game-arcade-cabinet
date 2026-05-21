#controls everything about the UI, including the contract signing. 
extends Control

#variables
var _start_time := 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#connect signals
	GameManager.decrement_kicks_remaining.connect(_on_update_kicks_remaining)
	GameManager.gamestate_update.connect(_on_change_state)
	#set initial text
	_on_update_kicks_remaining(GameManager.kicks_remaining) #TODO: more elegant solution.
	
	#get start time
	_start_time = Time.get_unix_time_from_system()
	
	#
	_clear_ui()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	#rotate the subtitle
	if $IdleMenu.visible:
		var time_delta = Time.get_unix_time_from_system() - _start_time
		var spin = 0.01 * sin(time_delta * 4)
		$IdleMenu/SubtitlePivot.rotation -= spin


#called when signal recieved
func _on_update_kicks_remaining(kick_count: int) -> void:
	%KicksRemainingLabel.text = ("KICKS REMAINING: " + str(kick_count))
	%KicksRemainingFancy.text = (str(kick_count))
	
func _on_change_state(state: GameManager.gamestates) -> void:
	_clear_ui()
	match state:
		GameManager.gamestates.IDLE:
			$IdleMenu.visible = true
		GameManager.gamestates.CONTRACT:
			pass
		GameManager.gamestates.KICKING:
			pass
		GameManager.gamestates.ROCK_KICKED:
			pass
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



func _clear_ui() -> void:
	var menus = get_children()
	for menu in menus:
		menu.visible = false
	%ScoreElem.visible = false
	%KicksRemainingElem.visible = false
	%KicksRemainingFancy.visible = false
