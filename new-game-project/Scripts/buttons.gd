extends VBoxContainer

func _ready():
	get_tree().paused = false

func _on_start_button_pressed():
	get_tree().change_scene_to_file("res://scenes/game.tscn")
	
func _on_settings_button_pressed():
	get_tree().change_scene_to_file("res://scenes/settings_menu.tscn")

func _on_quit_button_pressed():
	get_tree().quit()
