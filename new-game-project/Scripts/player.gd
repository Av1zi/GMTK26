extends CharacterBody2D
@export var speed: float = 360.0
@export var lr_flag: bool = true
@export var rotate_flag: bool = true
@export var melee_range: float = 60.0 # Distance in front of the player to spawn the slash
var screen_size
var lr: bool = true
var aim_pos: Vector2 = Vector2(0, 0)
var is_shot_cd: bool = false
var is_melee_cd: bool = false # NEW
var push_dir: Vector2 = Vector2(0, 0)
var push_strength: float = 0.0
var push_timer: float = 0.0

@onready var body_lr: Node2D = $character
@onready var body_rotate: Node2D = $gun
@onready var body_lr_player: AnimationPlayer = $BodyLRPlayer
@onready var body_rotete_player: AnimationPlayer = $BodyRotatePlayer
@onready var move_trail_effect: GPUParticles2D = $MovementTrailEffect
@onready var bullet_scene = preload("res://scenes/bullet.tscn")
@onready var slash_scene = preload("res://scenes/slash.tscn") # NEW
@onready var bullet_spawn_pos: Node2D = $gun/BulletSpawnPoint
@onready var shot_timer: Timer = $ShotTimer
@onready var melee_timer: Timer = $MeleeTimer # NEW — add a Timer node named MeleeTimer in the scene
@onready var shot_effect: GPUParticles2D = $gun/ShootingEffect
@onready var body_lr_collider: CollisionShape2D = $CollisionBodyLR
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer

func _ready():
	screen_size = get_viewport_rect().size
	hide()

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
		shot_timer.start(0.2)

	# Melee input — NEW
	if Input.is_action_pressed("melee") and not is_melee_cd:
		melee()
		is_melee_cd = true
		melee_timer.start(0.4) # Slash cooldown, feel free to tune

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
	var spawn_trans = Transform2D(aim_pos.angle(), spawn_pos) # was body_rotate.rotation — that had the +PI/2 gun offset baked in
	
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
