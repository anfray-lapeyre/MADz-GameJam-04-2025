extends Node2D

var level_size : int = 0 #To makes sure it spawns the right number of pieces (changes in ready function later)
@export var ex_level_number: int
@export var ex_experience_list: Array[PackedScene] #List of experience to spawn (keeps the order)
@export var ex_spawn_position = Vector2(300,-100)
@export var ex_spawn_delay: float = 2.0
@export var ex_max_lives: int = 3
@export var ex_hurt_cooldown_time: float = 1.5
@export var ex_gravity_reverse_duration: float = 3.0
@export var ex_level_selection : PackedScene

var current_lives: int
var can_lose_life: bool = true
var current_index: int = 0 #helps to know at which experience we're at in the list.
var current_experience: Node = null #references the current experience, to connect signals.

func _ready() -> void:
	current_lives = ex_max_lives
	spawn_next_piece()

func spawn_next_piece():
	if current_index >= ex_experience_list.size():
		return
	var scene = ex_experience_list[current_index] #Exists just to make code more clean and not write ex_experience_list[current_index].instanciate every time
	current_experience = scene.instantiate()
	current_experience.global_position = ex_spawn_position
	add_child(current_experience)
	current_index += 1 #moves to the next experience in the array
		# connects the signal to this experience
	if current_experience.has_signal("sig_control_lost"):
		current_experience.sig_control_lost.connect(_on_piece_lost_control.bind(current_experience))

func _on_piece_lost_control(piece: Node) -> void: #Disconnects the signal after it's send so two pieces don't spawn at the same time
	piece.sig_control_lost.disconnect(_on_piece_lost_control)
	await get_tree().create_timer(ex_spawn_delay).timeout
	spawn_next_piece()
	# Check victory if the last piece has sent the signal
	if current_index >= ex_experience_list.size() and current_lives > 0 and piece == current_experience:
		await get_tree().create_timer(0.5).timeout # little delay
		handle_victory()

func _on_dead_zone_body_entered(body: Node2D) -> void: #connects with dead zone
	if not body is RigidBody2D:
		return
	if can_lose_life:
		lose_life()

func lose_life() -> void: #func when you loose life
	current_lives -= 1
	can_lose_life = false
	print("Vie perdue ! Il en reste : ", current_lives)
	# feather display change
	update_life_display()
	# Cooldown
	await get_tree().create_timer(ex_hurt_cooldown_time).timeout
	can_lose_life = true
	#Game over
	if current_lives <= 0:
		await handle_game_over()

func update_life_display():
	for i in ex_max_lives:
		var plume = get_node("LifeDisplay").get_node("Feather" + str(i + 1))
		plume.visible = false
		# Display of the feather according to the number of lives
	var lost_lives = ex_max_lives - current_lives
	if lost_lives < ex_max_lives:
		var active_plume = get_node("LifeDisplay").get_node("Feather" + str(lost_lives + 1))
		active_plume.visible = true

func handle_game_over() -> void:
	print("GAME OVER")
	var fade = $ScreenFade
	# makes the black out "fondu au noir"
	var tween = get_tree().create_tween()
	tween.tween_property(fade, "modulate:a", 1.0, 1.0) # noir en 1 seconde
	await tween.finished
	fade.visible = true
	reset_level()
	# Waits before respawning pieces
	await get_tree().create_timer(1.5).timeout
		# makes the light comes back
	var tween_back = get_tree().create_tween()
	tween_back.tween_property(fade, "modulate:a", 0.0, 1.0)
	await tween_back.finished
	fade.visible = false

func reset_level():
	# deletes current piece if it exists
	if current_experience and is_instance_valid(current_experience):
		current_experience.queue_free()
	current_index = 0
	current_lives = ex_max_lives
	update_life_display()
	for child in get_children():
		if child.name.begins_with("obj_experience"): # ou autre préfixe commun
			child.queue_free()
	spawn_next_piece()

func handle_victory():
	print("VICTORY")
	var fade = $ScreenFade
	var tween = get_tree().create_tween()
	tween.tween_property(fade, "modulate:a", 1.0, 1.0)
	await tween.finished
	#records progression
	var this_level = ex_level_number # adapt according to level
	if this_level >= GlbGameManager.highest_unlocked_level:
		GlbGameManager.highest_unlocked_level = this_level + 1
		GlbGameManager.save_progress()
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_packed(ex_level_selection)
