extends Control

@export var ex_level_selection_menu : PackedScene 
@export var ex_controls_menu : PackedScene 
@export var ex_settings_menu : PackedScene 

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_packed(ex_level_selection_menu)

func _on_controls_button_pressed() -> void:
	get_tree().change_scene_to_packed(ex_controls_menu)

func _on_settings_button_pressed() -> void:
	get_tree().change_scene_to_packed(ex_settings_menu)
