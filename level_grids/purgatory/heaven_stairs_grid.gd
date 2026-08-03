extends Grid
class_name HeavenStairsGrid

@onready var gate_collision := $"rock_kicking_heaven_gate/heaven_gates_armature/Skeleton3D/@StaticBody3D@24976"
@onready var gate_anim := $rock_kicking_heaven_gate/AnimationPlayer

var purgatory_kicks = GameManager.kicks_remaining - GameManager.heaven_kick_count

func open_gates() -> void:
	gate_anim.play("heaven_gates_open")
	#gate_collision.collision_layer = 0
	#gate_collision.collision_mask = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	purgatory_kicks = GameManager.kicks_remaining - GameManager.heaven_kick_count
	$SignHelper/SubViewport/SignText.text = "Until\nheaven:\n" + str(purgatory_kicks)
	GameManager.decrement_kicks_remaining.connect(_on_update_kicks_remaining)
	GameManager.gamestate_update.connect(_on_switch_state)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_update_kicks_remaining(kick_count: int) -> void:
	purgatory_kicks = kick_count - GameManager.heaven_kick_count
	$SignHelper/SubViewport/SignText.text = "Until\nheaven:\n" + str(purgatory_kicks)

func _on_switch_state(state: GameManager.gamestates, cause: String) -> void:
	# when the game gets to idle after hitting 0 purgatory kicks open the gate
	# having the cause means it will only happen after player walks to rock
	if (
		purgatory_kicks == 0 and
		state == GameManager.gamestates.IDLE and
		cause == "player got to rock"
	):
		$GateOpenCamera.make_current()
		await get_tree().create_timer(1.0)
		open_gates()
