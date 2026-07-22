extends CharacterBody2D

@export var speed: float = 360.0
@export var lr_flag: bool = true # Enable body left right animation
@export var rotate_flag: bool = true # Enable body rotation 

var screen_size # Size of the game window.
var lr: bool = true # Default face right
var aim_pos: Vector2 = Vector2(0, 0)
var is_shot_cd: bool = false
var push_dir: Vector2 = Vector2(0, 0)
var push_strength: float = 0.0
var push_timer: float = 0.0

# Reference (Fixed Paths to match Scene Tree)
@onready var body_lr: Node2D = $character
@onready var body_rotate: Node2D = $gun
@onready var body_lr_player: AnimationPlayer = $BodyLRPlayer
@onready var body_rotete_player: AnimationPlayer = $BodyRotatePlayer
@onready var move_trail_effect: GPUParticles2D = $MovementTrailEffect
@onready var bullet_scene = preload("res://scenes/bullet.tscn")
@onready var bullet_spawn_pos: Node2D = $gun/BulletSpawnPoint
@onready var shot_timer: Timer = $ShotTimer
@onready var shot_effect: GPUParticles2D = $gun/ShootingEffect
@onready var body_lr_collider: CollisionShape2D = $CollisionBodyLR#Changed to CollisionShape2D/Polygon2D based on standard Godot nodes
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer

func _ready():
	screen_size = get_viewport_rect().size
	hide()

func _physics_process(delta):
	velocity = Vector2.ZERO # The player's movement vector.
	
	# Movement input
	if Input.is_action_pressed("move_right"):
		velocity.x += 1
	if Input.is_action_pressed("move_left"):
		velocity.x -= 1
	if Input.is_action_pressed("move_down"):
		velocity.y += 1
	if Input.is_action_pressed("move_up"):
		velocity.y -= 1
		
	# Shot input
	if Input.is_action_pressed("shot") and not is_shot_cd:
		shoot()
		is_shot_cd = true
		shot_timer.start(0.2)
		
	# Normalize velocity if move along x and y together
	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
		move_trail_effect.emitting = true # Play movement trail effect
		
	# Handle body_lr
	update_body_lr()
	
	# Handle aim toward mouse every frame
	update_body_rotate(get_global_mouse_position())
	
	
	# Limit the player movement
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
	# Play animations based on movement, but let the mouse handle rotation
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
	# Play shoot sound
	audio_player.play()

func set_push(dir: Vector2, strength: float, timer: float):
	push_dir = dir
	push_strength = strength
	push_timer = timer

func _on_shot_timer_timeout():
	is_shot_cd = false
