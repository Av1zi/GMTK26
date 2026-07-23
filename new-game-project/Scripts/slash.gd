extends Area2D
@export var damage: int = 20
@export var lifetime: float = 0.5 # How long the slash hitbox stays active
@onready var bullet_particle = preload("res://scenes/bullet_particle.tscn")
@onready var bullet_hit_sound = preload("res://scenes/bullet_hit_sound.tscn")

var hit_enemies: Array = [] # Prevent hitting the same enemy multiple times in one swing

func setup(trans: Transform2D, dmg:float):
	transform = trans
	damage = dmg
	

func _ready():
	$AnimationPlayer.play("slash")
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _on_body_entered(body):
	if body.is_in_group("enemy") and not hit_enemies.has(body):
		hit_enemies.append(body)
		body.get_hit(damage, global_transform)
		var bullet_effect = bullet_particle.instantiate()
		get_tree().root.add_child(bullet_effect)
		bullet_effect.setup(global_transform)
		var bullet_hit_player = bullet_hit_sound.instantiate()
		get_tree().root.add_child(bullet_hit_player)
		bullet_hit_player.play()
