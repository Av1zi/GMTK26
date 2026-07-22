extends CharacterBody2D
signal enemy_destroyed(enemy)
@export var health: int = 100
@export var speed: float = 50.0
@export var attack_damage: int = 10 # NEW
@export var attack_cooldown: float = 1.0 # NEW — seconds between hits while player is in range
var player: CharacterBody2D
var push_dir: Vector2 = Vector2(0, 0)
var push_strength: float = 0.0
var push_timer: float = 0.0
var player_in_range: bool = false # NEW
var can_attack: bool = true # NEW
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var damage_text: Label = $DamageTextContainer/DamageText
@onready var blood_particle = preload("res://scenes/blood_particle.tscn")
@onready var attack_area: Area2D = $AttackArea # NEW
@onready var attack_timer: Timer = $AttackTimer # NEW

func _ready():
	damage_text.visible = false

func setup(pos: Vector2, _player: CharacterBody2D):
	position = pos
	player = _player

func _physics_process(delta):
	var dir = (player.global_position - global_position).normalized()
	position += dir * delta * speed
	push_back(delta)
	

	if player_in_range and can_attack:
		attack_player()

func attack_player(): # NEW
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
	animation_tree['parameters/conditions/is_damaged'] = true
	if health <= 0:
		animation_tree['parameters/conditions/is_destroyed'] = true
	var bleeding_effect = blood_particle.instantiate()
	get_tree().root.add_child(bleeding_effect)
	bleeding_effect.setup(bullet_trans)
	set_push(Vector2.RIGHT.rotated(bullet_trans.get_rotation()), 150.0, 0.1)

func destroy():
	enemy_destroyed.emit(self)
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
