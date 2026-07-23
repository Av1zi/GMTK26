extends CharacterBody2D
signal enemy_destroyed(enemy, xp_reward)

# Base stats (tune these — this is what a round-1 enemy looks like)
@export var base_health: int = 100
@export var base_speed: float = 50.0
@export var base_attack_damage: int = 10
@export var base_xp_reward: int = 10


# Difficulty scaling
@export var difficulty_growth: float = 0.15   # +15% stats per round, exponential
@export var size_growth: float = 0.05         # +5% size per round
@export var min_scale: float = 0.6
@export var max_scale: float = 3
var max_health: int

@export var time_gained_on_death: float = 5.0
@export var attack_cooldown: float = 1.0
@export var spawn_invincible_time: float = 1.0
@export var flash_interval: float = 0.1

var health: int
var speed: float
var attack_damage: int
var xp_reward: int
var size_scale: float = 1.0

var player: CharacterBody2D
var push_dir: Vector2 = Vector2(0, 0)
var push_strength: float = 0.0
var push_timer: float = 0.0
var player_in_range: bool = false
var can_attack: bool = true
var is_invincible: bool = false
var original_collision_layer: int = 2
var original_collision_mask: int = 2

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var damage_text: Label = $DamageTextContainer/DamageText
@onready var blood_particle = preload("res://Scenes/blood_particle.tscn")
@onready var attack_area: Area2D = $AttackArea
@onready var attack_timer: Timer = $AttackTimer
@onready var character_sprite = $CharacterSprite

@onready var hurt_audio_player: AudioStreamPlayer = $HurtAudioPlayer
@onready var spawn_audio_player: AudioStreamPlayer = $SpawnAudioPlayer
@onready var hit_audio_player: AudioStreamPlayer = $HitAudioPlayer
@onready var die_audio_player: AudioStreamPlayer = $DieAudioPlayer
@export var hurt_sounds: Array[AudioStream] = []
@export var spawn_sounds: Array[AudioStream] = []
@export var die_sounds: Array[AudioStream] = []
@export var hit_sounds: Array[AudioStream] = []

func play_random_pitch(player: AudioStreamPlayer, min_pitch: float = 0.9, max_pitch: float = 1.1):
	player.pitch_scale = randf_range(min_pitch, max_pitch)
	player.play()

func _ready():
	play_spawn_invincibility()
	damage_text.visible = false
	spawn_audio_player.stream = spawn_sounds[randi() % spawn_sounds.size()]
	play_random_pitch(spawn_audio_player)

func setup(pos: Vector2, _player: CharacterBody2D, round_number: int = 1):
	position = pos
	player = _player
	apply_difficulty_scaling(round_number)

func apply_difficulty_scaling(round_number: int):
	var difficulty_multiplier = pow(1.0 + difficulty_growth, round_number - 1)
	size_scale = clamp(1.0 + (round_number - 1) * size_growth, min_scale, max_scale)

	health = int(base_health * difficulty_multiplier * size_scale)
	max_health = health
	attack_damage = int(base_attack_damage * difficulty_multiplier)
	xp_reward = int(base_xp_reward * difficulty_multiplier)
	speed = base_speed

	scale = Vector2(size_scale, size_scale)
	
func _physics_process(delta):
	if is_invincible:
		push_back(delta)
		return
	var dir = (player.global_position - global_position).normalized()
	position += dir * delta * speed
	push_back(delta)
	if player_in_range and can_attack:
		attack_player()

func attack_player():
	hit_audio_player.stream = hit_sounds[randi() % hit_sounds.size()]
	play_random_pitch(hit_audio_player)
	can_attack = false
	attack_timer.start(attack_cooldown)
	player.get_hit(attack_damage, global_transform)

func _on_attack_area_body_entered(body):
	if body == player:
		player_in_range = true

func _on_attack_area_body_exited(body):
	if body == player:
		player_in_range = false

func _on_attack_timer_timeout():
	can_attack = true

func get_hit(damage: int, bullet_trans: Transform2D):
	health -= damage
	damage_text.text = str(damage)
	damage_text.visible = true
	animation_tree['parameters/get_damage/OneShot/request'] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	hurt_audio_player.stream = hurt_sounds[randi() % hurt_sounds.size()]
	play_random_pitch(hurt_audio_player)   # NEW
	update_visual_size()
	if scale.x <= min_scale + 0.01 or health <= 0:
		animation_tree['parameters/conditions/is_destroyed'] = true
	var bleeding_effect = blood_particle.instantiate()
	get_tree().root.add_child(bleeding_effect)
	bleeding_effect.setup(bullet_trans)
	set_push(Vector2.RIGHT.rotated(bullet_trans.get_rotation()), 150.0, 0.1)
	
func update_visual_size():
	var health_percent = clamp(float(health) / float(max_health), 0.0, 1.0)
	# Map health percent directly onto the scale range [min_scale, size_scale]
	var current_scale = lerp(min_scale, size_scale, health_percent)
	scale = Vector2(current_scale, current_scale)

func destroy():
	set_physics_process(false)
	play_random_pitch(die_audio_player)
	get_tree().call_group("game_timer", "modify_time", time_gained_on_death)
	enemy_destroyed.emit(self, xp_reward)
	collision_layer = 0   # NEW — bullets can no longer detect this body
	collision_mask = 0    # NEW — this body no longer detects anything either
	visible = false
	await die_audio_player.finished
	queue_free()

func set_push(dir: Vector2, strength: float, timer: float):
	push_dir = -dir
	push_strength = strength
	push_timer = timer

func push_back(delta: float):
	if push_timer > 0.0:
		position -= push_dir * push_strength * delta
		push_timer -= delta
	else:
		push_timer = 0.0

func _on_animation_tree_animation_finished(anim_name):
	if anim_name == "get_damage":
		damage_text.visible = false
	elif anim_name == "destroy":
		animation_tree['parameters/conditions/is_destroyed'] = false
		destroy()

func play_spawn_invincibility():
	is_invincible = true
	original_collision_layer = collision_layer
	original_collision_mask = collision_mask
	collision_layer = 0
	collision_mask = 0
	var flashes := int(spawn_invincible_time / flash_interval)
	for i in flashes:
		character_sprite.visible = false
		await get_tree().create_timer(flash_interval / 2.0).timeout
		character_sprite.visible = true
		await get_tree().create_timer(flash_interval / 2.0).timeout
	character_sprite.visible = true
	collision_layer = original_collision_layer
	collision_mask = original_collision_mask
	is_invincible = false
