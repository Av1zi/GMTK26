# LevelUpUI.gd
extends CanvasLayer

@onready var option_a: Button = $"Control/Panel/VBoxContainer/HSplitContainer/OptionA"
@onready var option_b: Button = $"Control/Panel/VBoxContainer/HSplitContainer/OptionB"
@onready var skip_button: Button = $"Control/Panel/VBoxContainer/SkipButton"
@onready var desc_a: Label = $"Control/Panel/VBoxContainer/HSplitContainer2/DescA"
@onready var desc_b: Label = $"Control/Panel/VBoxContainer/HSplitContainer2/DescB"
@export var upgrade_pool: Node

var player: CharacterBody2D
var current_choices: Array = []
var pending_levelups: int = 0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	option_a.pressed.connect(_on_choice.bind(0))
	option_b.pressed.connect(_on_choice.bind(1))
	skip_button.pressed.connect(_on_skip)

func setup(p: CharacterBody2D):
	print("LevelUpUI setup called with: ", p)   # TEMP
	player = p
	

func show_next_choice():
	var pool = upgrade_pool.get_pool()
	pool.shuffle()
	current_choices = [pool[0], pool[1]]

	option_a.text = current_choices[0]["name"]
	desc_a.text = current_choices[0]["desc"] + "\n(+%.2fs/shot cost)" % current_choices[0]["time_cost"]
	option_b.text = current_choices[1]["name"]
	desc_b.text = current_choices[1]["desc"] + "\n(+%.2fs/shot cost)" % current_choices[1]["time_cost"]

	get_tree().paused = true
	show()

func _on_choice(index: int):
	var choice = current_choices[index]
	print("player is: ", player)   # TEMP
	choice["apply"].call(player)
	player.shot_timer_reduction -= choice["time_cost"]
	_close_and_advance()

func _on_skip():
	_close_and_advance()

func _close_and_advance():
	pending_levelups -= 1
	if pending_levelups > 0:
		show_next_choice()  # handle rapid double level-ups
	else:
		get_tree().paused = false
		hide()


func _on_player_leveled_up(new_level: Variant) -> void:
	pending_levelups += 1
	if not visible:
		show_next_choice()
