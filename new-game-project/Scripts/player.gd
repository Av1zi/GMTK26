extends CharacterBody2D
@export var speed: float = 360.0
@export var lr_flag: bool = true
@export var rotate_flag: bool = true
@export var melee_range: float = 20.0 # Distance in front of the player to spawn the slash
@export var iframe_duration: float = 0.8
@export var level: int = 1
@export var current_xp: int = 0
@export var base_xp_to_level: int = 100
@export var xp_growth_rate: float = 1.25  # each level needs 25% more XP than the last
@export var shot_timer_reduction = -0.5
@export var shot_cooldown: float = 0.5
@export var melee_cooldown: float = 1.2
var screen_size
var lr: bool = true
var aim_pos: Vector2 = Vector2(0, 0)
var is_shot_cd: bool = false
var is_melee_cd: bool = false 
var push_dir: Vector2 = Vector2(0, 0)
var push_strength: float = 0.0
var push_timer: float = 0.0

@onready var body_lr: Node2D = $character
@onready var body_rotate: Node2D = $gun
@onready var body_lr_player: AnimationPlayer = $BodyLRPlayer
@onready var body_rotete_player: AnimationPlayer = $BodyRotatePlayer
@onready var move_trail_effect: GPUParticles2D = $MovementTrailEffect
@onready var bullet_scene = preload("res://scenes/bullet.tscn")
@onready var slash_scene = preload("res://scenes/slash.tscn") 
@onready var bullet_spawn_pos: Node2D = $gun/BulletSpawnPoint
@onready var shot_timer: Timer = $ShotTimer
@onready var melee_timer: Timer = $MeleeTimer
@onready var shot_effect: GPUParticles2D = $gun/ShootingEffect
@onready var body_lr_collider: CollisionShape2D = $CollisionBodyLR
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var iframe_timer: Timer = $IFrameTimer 
var invincible: bool = false

signal xp_changed(current_xp, xp_to_next_level)
signal leveled_up(new_level)

func get_xp_to_next_level() -> int:
	return int(base_xp_to_level * pow(xp_growth_rate, level - 1))

func add_xp(amount: int):
	current_xp += amount
	var needed = get_xp_to_next_level()
	while current_xp >= needed:
		current_xp -= needed
		level += 1
		needed = get_xp_to_next_level()
		leveled_up.emit(level)
	xp_changed.emit(current_xp, needed)

func _ready():
	screen_size = get_viewport_rect().size
	hide()
	#xp_changed.emit(current_xp, get_xp_to_next_level())

func _physics_process(delta):
	velocity = Vector2.ZERO

	if Input.is_action_pressed("move_right"):
		velocity.x += 1
	if Input.is_action_pressed("move_left"):
		velocity.x -= 1
	if Input.is_action_pressed("move_down"):
		velocity.y += 1
	if Input.is_action_pressed("move_up"):
		velocity.y -= 1

	if Input.is_action_pressed("shot") and not is_shot_cd:
		shoot()
		is_shot_cd = true
		shot_timer.start(shot_cooldown)

	# Melee input — NEW
	if Input.is_action_pressed("melee") and not is_melee_cd:
		melee()
		is_melee_cd = true
		melee_timer.start(melee_cooldown) # Slash cooldown, feel free to tune

	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
		move_trail_effect.emitting = true

	update_body_lr()
	update_body_rotate(get_global_mouse_position())

	position.x = clamp(position.x, 0, screen_size.x)
	position.y = clamp(position.y, 0, screen_size.y)
	move_and_slide()

func _input(event):
	if event is InputEventMouseMotion:
		update_body_rotate(event.position)

func setup(pos: Vector2):
	position = pos
	show()

func update_body_lr():
	if not lr_flag:
		return
	if velocity.length() > 0:
		body_lr_player.play("MoveR")
	else:
		body_lr_player.play("IdleR")

func update_body_rotate(mouse_pos: Vector2):
	if not rotate_flag:
		return
	var dir_to_mouse = (mouse_pos - global_position)
	body_rotate.rotation = dir_to_mouse.angle() + PI/2
	body_lr.rotation = dir_to_mouse.angle() + PI/2
	aim_pos = dir_to_mouse.normalized()

func shoot():
	get_tree().call_group("game_timer", "modify_time", shot_timer_reduction)
	body_rotete_player.play("Shot")
	var bullet = bullet_scene.instantiate()
	bullet.setup(bullet_spawn_pos.global_transform)
	get_tree().root.add_child(bullet)
	shot_effect.emitting = true
	set_push(Vector2.RIGHT.rotated(body_rotate.rotation), 200.0, 0.2)
	audio_player.play()

func melee():
	body_rotete_player.play("Shot")
	var slash = slash_scene.instantiate()
	
	var spawn_pos = global_position + aim_pos * melee_range
	var spawn_trans = Transform2D(aim_pos.angle(), spawn_pos) 
	
	slash.setup(spawn_trans)
	get_tree().root.add_child(slash)
	set_push(Vector2.RIGHT.rotated(aim_pos.angle()), 120.0, 0.15) # same fix here for player recoil direction
	audio_player.play()

func set_push(dir: Vector2, strength: float, timer: float):
	push_dir = dir
	push_strength = strength
	push_timer = timer

func _on_shot_timer_timeout():
	is_shot_cd = false

func _on_melee_timer_timeout(): # NEW
	is_melee_cd = false

func get_hit(time: int, attacker_trans: Transform2D): # NEW
	if invincible:
		return
	set_push(Vector2.RIGHT.rotated(attacker_trans.get_rotation()), 150.0, 0.1)
	audio_player.play()
	get_tree().call_group("game_timer", "modify_time", time)
	start_iframes() 
	
func start_iframes():
	invincible = true
	iframe_timer.start(iframe_duration)
	flash_sprite()
	
func flash_sprite(): 
	var tween = create_tween()
	tween.set_loops(int(iframe_duration / 0.2))
	tween.tween_property(body_lr, "modulate:a", 0.3, 0.1)
	tween.tween_property(body_lr, "modulate:a", 1.0, 0.1)

func _on_i_frame_timer_timeout(): # NEW — connect to IFrameTimer's timeout
	invincible = false
	body_lr.modulate.a = 1.0 # Ensu
