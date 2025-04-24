extends Control

@export var ex_total_levels : int
@export var ex_level_1 : PackedScene
@export var ex_level_2 : PackedScene
@export var ex_level_3 : PackedScene
@export var ex_level_4 : PackedScene
@export var ex_level_5 : PackedScene
@export var ex_level_6 : PackedScene
@export var ex_start_menu : PackedScene

func _on_level_1_pressed() -> void:
	get_tree().change_scene_to_packed(ex_level_1)

func _on_level_2_pressed() -> void:
	get_tree().change_scene_to_packed(ex_level_2)

func _on_level_3_pressed() -> void:
	get_tree().change_scene_to_packed(ex_level_3)

func _on_level_4_pressed() -> void:
	get_tree().change_scene_to_packed(ex_level_4)

func _on_level_5_pressed() -> void:
	get_tree().change_scene_to_packed(ex_level_5)

func _on_level_6_pressed() -> void:
	get_tree().change_scene_to_packed(ex_level_6)

func _on_return_button_pressed() -> void:
	get_tree().change_scene_to_packed(ex_start_menu)

func _ready():
	GlbGameManager.load_progress()
	for i in range(1, ex_total_levels + 1):
		var button = $LevelButtons.get_node("Level" + str(i))
		button.disabled = i > GlbGameManager.highest_unlocked_level
