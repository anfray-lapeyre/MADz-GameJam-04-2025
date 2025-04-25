extends Control

func _ready():
	GlbAudioPlayer.play_music()

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/UI/map_level_selection.tscn")
