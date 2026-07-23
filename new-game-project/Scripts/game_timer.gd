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
@export var float_scale_min: float = 0.5 # Scale for 0.5 time change
@export var float_scale_max: float = 1.5 # Scale for 10.0 time change

var time_left: float
var is_active: bool = false

# Internal state for animations
var _base_scale: Vector2
var _base_rotation: float
var _wiggle_time: float = 0.0
var _effect_tween: Tween

func _ready() -> void:
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

	_wiggle_time += delta * wiggle_speed
	timer_label.rotation_degrees = _base_rotation + (sin(_wiggle_time) * wiggle_intensity)

func start() -> void:
	is_active = true

func stop() -> void:
	is_active = false

func modify_time(amount: float) -> void:
	time_left += amount
	if time_left < 0.0: 
		time_left = 0.0
	
	var is_positive: bool = amount > 0
	_play_pop_effect(is_positive)
	_spawn_floating_text(amount)

func _play_pop_effect(is_positive: bool) -> void:
	if _effect_tween and _effect_tween.is_valid():
		if _effect_tween.is_running():
			return
		_effect_tween.kill()

	_effect_tween = create_tween().set_parallel(true)
	
	var target_color: Color = Color.GREEN if is_positive else Color.RED
	var target_scale: Vector2 = _base_scale * (pop_scale_positive if is_positive else pop_scale_negative)

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
	float_label.add_theme_font_size_override("font_size", int(timer_label.get_theme_font_size("font_size") * 0.75))
	
	float_label.top_level = true 
	add_child(float_label) 
	
	# Set pivot to center so the text scales outward from its middle
	float_label.pivot_offset = float_label.get_minimum_size() / 2.0
	
	var random_offset := Vector2(
		randf_range(-timer_label.size.x * 0.8, timer_label.size.x * 0.8),
		randf_range(-timer_label.size.y * 0.5, timer_label.size.y * 0.5)
	)
	float_label.global_position = timer_label.global_position + (timer_label.size / 2.0) + random_offset

	var x_drift := randf_range(-60.0, 60.0)
	var y_drift := randf_range(-40.0, -80.0)
	var random_rot := randf_range(-0.4, 0.4)
	
	# NEW: Calculate target scale based on the absolute value of the change.
	# We clamp the amount between 0.5 and 10.0, then map it to our min/max export values.
	var abs_amount: float = abs(amount)
	var dynamic_scale_multiplier: float = remap(clampf(abs_amount, 0.5, 10.0), 0.5, 10.0, float_scale_min, float_scale_max)
	var target_scale := Vector2(dynamic_scale_multiplier, dynamic_scale_multiplier)
	
	# Start at 0 so it pops into existence
	float_label.scale = Vector2.ZERO 

	var float_tween := create_tween().set_parallel(true)
	
	# 1. Pop in to our dynamically calculated target_scale!
	float_tween.tween_property(float_label, "scale", target_scale, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	# 2. Explode outward
	float_tween.tween_property(float_label, "global_position:y", float_label.global_position.y + y_drift, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	float_tween.tween_property(float_label, "global_position:x", float_label.global_position.x + x_drift, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_LINEAR)
	
	# 3. Add dynamic rotation
	float_tween.tween_property(float_label, "rotation", random_rot, 1.0).set_ease(Tween.EASE_OUT)

	# 4. Fade out
	float_tween.tween_property(float_label, "modulate:a", 0.0, 1.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)
	
	float_tween.chain().tween_callback(float_label.queue_free)
