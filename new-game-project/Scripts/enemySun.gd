extends CharacterBody2D
signal enemy_destroyed(enemy, xp_reward)

@export var base_health: int = 100
@export var base_speed: float = 50.0
@export var base_xp_reward: int = 15

@export var difficulty_growth: float = 0.15
@export var size_growth: float = 0.05
@export var min_scale: float = 0.6
@export var max_scale: float = 3
var max_health: int

@export var preferred_distance: float = 480.0
@export var distance_tolerance: float = 40.0
@export var shot_cooldown: float = 2
@export var time_gained_on_death: float = 5.0
@export var spawn_invincible_time: float = 1.0
@export var flash_interval: float = 0.1

var health: int
var speed: float
var xp_reward: int
var size_scale: float = 1.0

var is_invincible: bool = false
var original_collision_layer: int = 2
var original_collision_mask: int = 2

var player: CharacterBody2D
var push_dir: Vector2 = Vector2(0, 0)
var push_strength: float = 0.0
var push_timer: float = 0.0
var is_shot_cd: bool = false

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var damage_text: Label = $DamageTextContainer/DamageText
@onready var blood_particle = preload("res://Scenes/blood_particle.tscn")
@onready var bullet_scene = preload("res://Scenes/SunBullet.tscn")
@onready var character_sprite: Sprite2D = $CharacterSprite
@onready var bullet_spawn_pos: Node2D = $BulletSpawnPoint
@onready var shot_timer: Timer = $ShotTimer
@onready var screen_size = Vector2.ZERO

func _ready():
	play_spawn_invincibility()
	damage_text.visible = false
	shot_timer.one_shot = true
	shot_timer.timeout.connect(_on_shot_timer_timeout)
	screen_size = get_viewport_rect().size

func setup(pos: Vector2, _player: CharacterBody2D, round_number: int = 1):
	position = pos
	player = _player
	apply_difficulty_scaling(round_number)

func apply_difficulty_scaling(round_number: int):
	var difficulty_multiplier = pow(1.0 + difficulty_growth, round_number - 1)
	size_scale = clamp(1.0 + (round_number - 1) * size_growth, min_scale, max_scale)

	health = int(base_health * difficulty_multiplier * size_scale)
	max_health = health
	xp_reward = int(base_xp_reward * difficulty_multiplier)
	speed = base_speed

	scale = Vector2(size_scale, size_scale)

func update_visual_size():
	var health_percent = clamp(float(health) / float(max_health), 0.0, 1.0)
	var current_scale = lerp(min_scale, size_scale, health_percent)
	scale = Vector2(current_scale, current_scale)

func _physics_process(delta):
	if is_invincible:
		push_back(delta)
		return
	if player == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var to_player = player.global_position - global_position
	var dist = to_player.length()
	var dir = to_player.normalized()

	character_sprite.rotation = dir.angle() - PI/2
	bullet_spawn_pos.rotation = dir.angle()

	if dist > preferred_distance + distance_tolerance:
		velocity = dir * speed
	elif dist < preferred_distance - distance_tolerance:
		velocity = -dir * speed
	else:
		velocity = Vector2.ZERO

	if dist <= preferred_distance + distance_tolerance and not is_shot_cd:
		shoot()

	push_back(delta)
	move_and_slide()

func shoot():
	is_shot_cd = true
	shot_timer.start(shot_cooldown)
	var bullet = bullet_scene.instantiate()
	bullet.setup(bullet_spawn_pos.global_transform)
	get_tree().root.add_child(bullet)

func get_hit(damage: int, bullet_trans: Transform2D):
	health -= damage
	damage_text.text = str(damage)
	damage_text.visible = true
	animation_tree['parameters/conditions/is_damaged'] = true
	update_visual_size()   # NEW — check size/death BEFORE deciding is_destroyed

	if scale.x <= min_scale + 0.01 or health <= 0:   # CHANGED — epsilon + health fallback
		animation_tree['parameters/conditions/is_destroyed'] = true

	var bleeding_effect = blood_particle.instantiate()
	get_tree().root.add_child(bleeding_effect)
	bleeding_effect.setup(bullet_trans)
	set_push(Vector2.RIGHT.rotated(bullet_trans.get_rotation()), 150.0, 0.1)

func destroy():
	get_tree().call_group("game_timer", "modify_time", time_gained_on_death)
	enemy_destroyed.emit(self, xp_reward)
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
		animation_tree['parameters/conditions/is_damaged'] = false
	elif anim_name == "destroy":
		animation_tree['parameters/conditions/is_destroyed'] = false
		destroy()

func _on_shot_timer_timeout():
	is_shot_cd = false

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
