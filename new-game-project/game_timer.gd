class_name GameTimer
extends Control

signal time_expired

@export_category("Node Setup")
@export var timer_label: Label
@export var group_name: String = "game_timer"

@export_category("Timer Settings")
@export var initial_time: float = 60.0
@export var auto_start: bool = true

@export_category("Game Feel Settings")
@export var wiggle_intensity: float = 1.5 
@export var wiggle_speed: float = 8.0
@export var pop_scale_positive: float = 1.4
@export var pop_scale_negative: float = 0.7

var time_left: float
var is_active: bool = false

# Internal state for animations
var _base_scale: Vector2
var _base_rotation: float
var _wiggle_time: float = 0.0
var _effect_tween: Tween

func _ready() -> void:
	# Register this node to a group so other scripts can find it via call_group
	add_to_group(group_name)
	
	if not timer_label:
		push_error("GameTimer: No Label assigned! Please assign the child Label in the inspector.")
		return
		
	time_left = initial_time
	_base_scale = timer_label.scale
	_base_rotation = timer_label.rotation
	
	timer_label.pivot_offset = timer_label.size / 2.0
	
	if auto_start:
		start()

func _process(delta: float) -> void:
	if not is_active or not timer_label: 
		return

	time_left -= delta
	if time_left <= 0.0:
		time_left = 0.0
		is_active = false
		time_expired.emit()

	timer_label.text = "%.2f" % time_left
	timer_label.pivot_offset = timer_label.size / 2.0

	# Apply the wiggle to the child Label, keeping the root Control completely still
	_wiggle_time += delta * wiggle_speed
	timer_label.rotation_degrees = _base_rotation + (sin(_wiggle_time) * wiggle_intensity)

func start() -> void:
	is_active = true

func stop() -> void:
	is_active = false

# This is the function you will call from other nodes using call_group!
func modify_time(amount: float) -> void:
	time_left += amount
	if time_left < 0.0: 
		time_left = 0.0
	
	var is_positive: bool = amount > 0
	_play_pop_effect(is_positive)
	_spawn_floating_text(amount)

func _play_pop_effect(is_positive: bool) -> void:
	if _effect_tween and _effect_tween.is_valid():
		_effect_tween.kill()

	_effect_tween = create_tween().set_parallel(true)
	
	var target_color: Color = Color.GREEN if is_positive else Color.RED
	var target_scale: Vector2 = _base_scale * (pop_scale_positive if is_positive else pop_scale_negative)

	# Target the timer_label for all visual tweaks
	_effect_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SPRING)
	_effect_tween.tween_property(timer_label, "scale", target_scale, 0.1)
	_effect_tween.tween_property(timer_label, "modulate", target_color, 0.1)

	_effect_tween.chain().set_parallel(true)
	_effect_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	_effect_tween.tween_property(timer_label, "scale", _base_scale, 0.4)
	
	_effect_tween.set_trans(Tween.TRANS_SINE)
	_effect_tween.tween_property(timer_label, "modulate", Color.WHITE, 0.3)

func _spawn_floating_text(amount: float) -> void:
	var float_label := Label.new()
	var is_positive: bool = amount > 0
	
	float_label.text = ("+" if is_positive else "") + "%.2f" % amount
	float_label.modulate = Color.GREEN if is_positive else Color.RED
	
	if timer_label.has_theme_font_override("font"):
		float_label.add_theme_font_override("font", timer_label.get_theme_font("font"))
	float_label.add_theme_font_size_override("font_size", int(timer_label.get_theme_font_size("font_size") * 0.6))
	
	float_label.top_level = true 
	add_child(float_label) # Add as a child of the Control
	
	var random_offset := Vector2(
		randf_range(-timer_label.size.x * 0.8, timer_label.size.x * 0.8),
		randf_range(-timer_label.size.y * 0.5, timer_label.size.y * 0.5)
	)
	float_label.global_position = timer_label.global_position + (timer_label.size / 2.0) + random_offset

	var float_tween := create_tween().set_parallel(true)
	float_tween.tween_property(float_label, "global_position:y", float_label.global_position.y - 60.0, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	float_tween.tween_property(float_label, "modulate:a", 0.0, 1.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)
	
	float_tween.chain().tween_callback(float_label.queue_free)
