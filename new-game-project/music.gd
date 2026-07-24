extends AudioStreamPlayer

func _ready() -> void:
	call_deferred("_persist")

func _persist() -> void:
	var root := get_tree().root
	if root.has_node("PersistentMusic"):
		# already exists from a previous load — kill this duplicate
		queue_free()
		return

	var old_parent := get_parent()
	old_parent.remove_child(self)
	root.add_child(self)
	name = "PersistentMusic"
