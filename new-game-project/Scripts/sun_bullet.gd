extends Area2D

@export var speed: float = 800.0
@export var damage: int = 30

@onready var bullet_particle = preload("res://scenes/bullet_particle.tscn")
@onready var bullet_hit_sound = preload("res://scenes/bullet_hit_sound.tscn")
@onready var hit_audio_player: AudioStreamPlayer = $HitAudioPlayer

func _physics_process(delta):
	position += transform.x * speed * delta

func setup(trans: Transform2D):
	transform = trans

func play_random_pitch(player: AudioStreamPlayer, min_pitch: float = 0.9, max_pitch: float = 1.1):
	player.pitch_scale = randf_range(min_pitch, max_pitch)
	player.play()

func _on_body_entered(body):
	play_random_pitch(hit_audio_player)
	if body.is_in_group("player"):
		body.get_hit(damage, global_transform)
	var bullet_effect = bullet_particle.instantiate()
	get_tree().root.add_child(bullet_effect)
	bullet_effect.setup(global_transform)
	var bullet_hit_player = bullet_hit_sound.instantiate()
	get_tree().root.add_child(bullet_hit_player)
	bullet_hit_player.play()
	queue_free()
