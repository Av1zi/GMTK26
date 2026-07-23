extends Node2D
@export var noise_shake_speed: float = 15.0
@export var noise_shake_strength: float = 16.0
@export var shake_decay_rate: float = 20.0
var start_pos: Vector2
var enemy_list: Array = []
var noise_i: float = 0.0
var shake_strength: float = 0.0
var round_number: int = 0
@onready var camera: Camera2D = $Camera2D
@onready var death_screen: Control = $"UILayer/HUD/Death Screen"
@onready var enemy_class = preload("res://Scenes/enemy.tscn")
@onready var sun_enemy_class = preload("res://Scenes/enemySun.tscn")
@onready var log_enemy_class = preload("res://Scenes/enemy_log.tscn")  # NEW
@onready var player: CharacterBody2D = $Player
@onready var noise = FastNoiseLite.new()
@onready var rand = RandomNumberGenerator.new()
@onready var xp_bar: ProgressBar = $UILayer/HUD/XPBar
@onready var level_label: Label = $UILayer/HUD/XPBar/LevelLabel
@onready var level_up_ui = $"Level up ui"

func _ready():
	var screen_size = get_viewport_rect().size
	start_pos = Vector2(screen_size.x/2, screen_size.y/2)
	player.setup(start_pos)
	player.xp_changed.emit(player.current_xp, player.get_xp_to_next_level())
	level_up_ui.setup(player)   # NEW
	rand.randomize()
	noise.seed = rand.randi()
	noise.frequency = 0.1

func _process(delta: float):
	if enemy_list.size() == 0:
		round_number += 1
		print("Spawning round: ", round_number)
		var n = randi_range(1, 6)   # CHANGED — up to 6 mobs per round
		for i in range(0, n):
			var enemy = pick_enemy_type()   # CHANGED — weighted pick
			enemy.connect("enemy_destroyed", on_enemy_destroyed)
			var pos = Vector2(randf_range(100, 1000), randf_range(150, 500))
			enemy.setup(pos, player, round_number)
			get_tree().root.add_child(enemy)
			enemy_list.append(enemy)
	shake_camera(delta)

func pick_enemy_type() -> Node:   # NEW
	var roll = randf()
	if roll < 0.10:
		return log_enemy_class.instantiate()   # 10% chance — rare
	elif roll < 0.55:
		return sun_enemy_class.instantiate()   # 45% chance
	else:
		return enemy_class.instantiate()       # 45% chance

func shake_camera(delta: float):
	shake_strength = lerp(shake_strength, 0.0, shake_decay_rate * delta)
	var shake_offset: Vector2
	shake_offset = get_noise_offset(delta, noise_shake_speed, shake_strength)
	camera.offset = shake_offset

func get_noise_offset(delta: float, speed: float, strength: float) -> Vector2:
	noise_i += delta * speed
	return Vector2(
		noise.get_noise_2d(1, noise_i) * strength,
		noise.get_noise_2d(100, noise_i) * strength
	)

func get_random_offset() -> Vector2:
	return Vector2(
		rand.randf_range(-shake_strength, shake_strength),
		rand.randf_range(-shake_strength, shake_strength)
	)

func on_enemy_destroyed(enemy, xp_reward):
	shake_strength = noise_shake_strength
	enemy_list.erase(enemy)
	player.add_xp(xp_reward)

func _on_game_timer_time_expired():
	get_tree().call_group("enemy", "queue_free")
	death_screen.visible = true
	get_tree().paused = true

func _on_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

func _on_player_leveled_up(new_level: Variant) -> void:
	level_label.text = "Level %d" % new_level

func _on_player_xp_changed(current_xp: Variant, xp_to_next_level: Variant) -> void:
	xp_bar.max_value = xp_to_next_level
	xp_bar.value = current_xp
