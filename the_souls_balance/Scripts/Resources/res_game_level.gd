extends Node2D

var experience_keywords = {
	"obj_experience_T_anger": "Family",
	"obj_experience_T_disgust": "Family",
	"obj_experience_T_fear": "Family",
	"obj_experience_T_joy": "Family",
	"obj_experience_T_sadness": "Family",
	
	"obj_experience_square_anger": "Daily Life",
	"obj_experience_square_disgust": "Daily Life",
	"obj_experience_square_fear": "Daily Life",
	"obj_experience_square_joy": "Daily Life",
	"obj_experience_square_sadness": "Daily Life",
	
	"obj_experience_LL_anger": "Health",
	"obj_experience_LL_disgust": "Health",
	"obj_experience_LL_fear": "Health",
	"obj_experience_LL_joy": "Health",
	"obj_experience_LL_sadness": "Health",
	
	"obj_experience_Z_anger": "Learning",
	"obj_experience_Z_disgust": "Learning",
	"obj_experience_Z_fear": "Learning",
	"obj_experience_Z_joy": "Learning",
	"obj_experience_Z_sadness": "Learning",
	
	"obj_experience_ZZ_anger" : "Work",
	"obj_experience_ZZ_disgust" : "Work",
	"obj_experience_ZZ_fear" : "Work",
	"obj_experience_ZZ_joy" : "Work",
	"obj_experience_ZZ_sadness" : "Work",
	
	"obj_experience_L_anger" : "Love",
	"obj_experience_L_disgust" : "Love",
	"obj_experience_L_fear" : "Love",
	"obj_experience_L_joy" : "Love",
	"obj_experience_L_sadness" : "Love",
	
	"obj_experience_U_anger" : "Surprise",
	"obj_experience_U_disgust" : "Surprise",
	"obj_experience_U_fear" : "Surprise",
	"obj_experience_U_joy" : "Surprise",
	"obj_experience_U_sadness" : "Surprise",
	
	"obj_experience_I_anger" : "Creativity",
	"obj_experience_I_disgust" : "Creativity",
	"obj_experience_I_fear" : "Creativity",
	"obj_experience_I_joy" : "Creativity",
	"obj_experience_I_sadness" : "Creativity",
	
	"obj_experience_X_anger" : "Social",
	"obj_experience_X_disgust" : "Social",
	"obj_experience_X_fear" : "Social",
	"obj_experience_X_joy" : "Social",
	"obj_experience_X_sadness" : "Social",
	
	
	"obj_circle" : "Cowardice",
	"obj_experience_shuriken" : "Selfishness",
	"obj_experience_drop" : "Betrayal",
	"obj_experience_ghost_i" : "Self Sacrifice",
	"obj_experience_slime_square" : "Kindness",
	"obj_experience_void_X" : "Care"
}

var level_size : int = 0 #To makes sure it spawns the right number of pieces (changes in ready function later)
@export var ex_level_number: int
@export var ex_experience_list: Array[PackedScene] #List of experience to spawn (keeps the order)
@export var ex_voice_over_list: Array[AudioStream] #List of voice overs for each experience
@export var ex_subtitle_list: Array[String] #List of life lost subtitles
@export var ex_life_lost_sfx_list: Array[AudioStream] #List of life lost SFX
@export var ex_life_lost_subtitle_list: Array[String] #List of life lost subtitles
var used_life_lost_sfx : Array[AudioStream]=[]

@export var ex_spawn_position = Vector2(300,-100)
@export var ex_spawn_delay: float = 2.0
@export var ex_max_lives: int = 3
@export var ex_hurt_cooldown_time: float = 1.5
@export var ex_gravity_reverse_duration: float = 3.0
@onready var pause_menu = $PauseLayer/PauseMenu
@onready var sfx_player= %LifeLostAudioPlayer
@onready var voice_over_player = %VoiceOverPlayer

var current_lives: int
var can_lose_life: bool = true
var current_index: int = 0 #helps to know at which experience we're at in the list.
var current_experience: Node = null #references the current experience, to connect signals.
var current_spawn_timer := Timer.new()
var balance_scene = preload("res://Scenes/Objects/ground_container.tscn")
@onready var base_balance_transform:Transform2D=$ground_container.transform
@onready var current_balance := $ground_container
@onready var subtitle_label := %VoiceOverLabel
@onready var life_lost_label := %LifeLostLabel

func _ready() -> void:
	add_child(current_spawn_timer)
	current_spawn_timer.wait_time = ex_spawn_delay
	current_spawn_timer.one_shot=true
	
	current_lives = ex_max_lives
	spawn_next_piece()
	pause_menu.visible = false
	$VictoryLabel.visible = false 

func spawn_next_piece():
	if current_index >= ex_experience_list.size():
		return
	var scene = ex_experience_list[current_index] #Exists just to make code more clean and not write ex_experience_list[current_index].instanciate every time
	current_experience = scene.instantiate()
	current_experience.global_position = ex_spawn_position
	add_child(current_experience)
	
	if ex_voice_over_list.size() >current_index:
		voice_over_player.stream= ex_voice_over_list[current_index]
		voice_over_player.play()
	if ex_subtitle_list.size() >current_index:
		subtitle_label.text= ex_subtitle_list[current_index]
		subtitle_label.rotation_degrees = randf_range(-9, 9.0)
		subtitle_label.scale=Vector2.ONE*1.2
		var tween = get_tree().create_tween()
		tween.tween_property(subtitle_label, "modulate:a", 1, 0.5)
		tween.set_parallel(true)
		tween.tween_property(subtitle_label, "scale", Vector2.ONE, 0.5).set_ease(Tween.EASE_IN)


	
	current_index += 1 #moves to the next experience in the array
		# connects the signal to this experience
	if current_experience.has_signal("sig_control_lost"):
		current_experience.sig_control_lost.connect(_on_piece_lost_control.bind(current_experience))
	update_next_piece_preview()
#Variable used in the 2 next functions, because we can't pass a parameter in a connection
var _piece : Node;


func _on_piece_lost_control(piece: Node) -> void: #Disconnects the signal after it's send so two pieces don't spawn at the same time
	_piece = piece
	piece.sig_control_lost.disconnect(_on_piece_lost_control)
	current_spawn_timer.start()
	var tween = get_tree().create_tween()
	tween.tween_property(subtitle_label, "modulate:a", 0, 0.5) # noir en 1 seconde
	if current_spawn_timer.is_connected("timeout",call_spawn_piece_and_check_victory):
		current_spawn_timer.disconnect("timeout",call_spawn_piece_and_check_victory)
	current_spawn_timer.connect("timeout",call_spawn_piece_and_check_victory)

func call_spawn_piece_and_check_victory() -> void:
	spawn_next_piece()
	# Check victory if the last piece has sent the signal
	if current_index >= ex_experience_list.size() and current_lives > 0 and _piece == current_experience:
		await get_tree().create_timer(0.5).timeout # little delay
		handle_victory()

func _on_dead_zone_body_entered(body: Node2D) -> void: #connects with dead zone
	if not body is RigidBody2D:
		return
	#We kill any piece that goes below the screen
	body.queue_free()
	if can_lose_life:
		lose_life()

func lose_life() -> void: #func when you loose life
	current_lives -= 1
	can_lose_life = false
	
	# Sélectionne un effet sonore aléatoire (en s'assurant qu'il n'est pas déjà utilisé)
	var selected_sfx = pick_random_sfx()

	# Joue le son associé à la perte de vie, si la liste n'est pas vide
	if ex_life_lost_sfx_list.size() > 0:
		sfx_player.stream = ex_life_lost_sfx_list[selected_sfx]
		sfx_player.play()

	# Affiche le sous-titre associé à la perte de vie, si la liste n'est pas vide
	if ex_life_lost_subtitle_list.size() > 0:
		life_lost_label.text = ex_life_lost_subtitle_list[selected_sfx]

		# Applique une rotation aléatoire entre -9° et 9° pour donner du caractère à l'affichage
		life_lost_label.rotation_degrees = randf_range(-9, 9.0)

		# Met le label à une échelle de 130% pour l'effet d'apparition
		life_lost_label.scale = Vector2.ONE * 1.3

		# Crée un tween pour animer l'apparition du label
		var tween = get_tree().create_tween()

		# Anime l'opacité de 0 à 1 en 0.5s pour le faire apparaître
		tween.tween_property(life_lost_label, "modulate:a", 1, 0.5)

		# Les deux animations suivantes se font en parallèle
		tween.set_parallel(true)

		# Anime l'échelle pour donner un effet de pop (de 130% à 110%)
		tween.tween_property(life_lost_label, "scale", Vector2.ONE * 1.1, 0.5).set_ease(Tween.EASE_IN)

		# Attend 2 secondes avant de lancer la prochaine animation
		tween.chain().tween_interval(2.0)

		# Fait disparaître le label en baissant l’opacité à 0 en 0.5s
		tween.chain().tween_property(life_lost_label, "modulate:a", 0.0, 0.5)
	print("Vie perdue ! Il en reste : ", current_lives)
	# feather display change
	update_life_display()
		#Game over
	if current_lives <= 0:
		if current_spawn_timer.is_connected("timeout",call_spawn_piece_and_check_victory):
			current_spawn_timer.disconnect("timeout",call_spawn_piece_and_check_victory)
		await handle_game_over()
		return
	# Cooldown
	await get_tree().create_timer(ex_hurt_cooldown_time).timeout
	can_lose_life = true

# Liste des SFX déjà joués pour éviter les répétitions
# ex_life_lost_sfx_list : tous les sons possibles
# used_life_lost_sfx : sons déjà joués

func pick_random_sfx() -> int:
	if ex_life_lost_sfx_list.size() <= 0:
		return -1
	
	# Si on a tout utilisé, on remet à zéro
	if used_life_lost_sfx.size() >= ex_life_lost_sfx_list.size():
		used_life_lost_sfx.clear()
	
	var selected := randi() % ex_life_lost_sfx_list.size()
	var selected_sfx := ex_life_lost_sfx_list[selected]
	
	# Vérifie si ce son a déjà été utilisé
	if used_life_lost_sfx.find(selected_sfx) != -1:
		# Si oui, tente de trouver le suivant disponible (jusqu’à 6 essais max)
		return pick_next_available_sfx((selected + 1) % ex_life_lost_sfx_list.size(), 10)
	else:
		# Sinon, on le stocke comme utilisé et on retourne son index
		used_life_lost_sfx.append(selected_sfx)
		return selected


func pick_next_available_sfx(value: int, remaining_recursion: int) -> int:
	if ex_life_lost_sfx_list.size() <= 0 or ex_life_lost_sfx_list[value%ex_life_lost_sfx_list.size()] == null:
		return -1
	
	if remaining_recursion <= 0:
		return -1
	
	if used_life_lost_sfx.size() >= ex_life_lost_sfx_list.size():
		used_life_lost_sfx.clear()
	
	var selected_sfx := ex_life_lost_sfx_list[value%ex_life_lost_sfx_list.size()]
	
	if used_life_lost_sfx.find(selected_sfx) != -1:
		# Récurse sur l’élément suivant
		return pick_next_available_sfx((value + 1) % ex_life_lost_sfx_list.size(), remaining_recursion - 1)
	else:
		used_life_lost_sfx.append(selected_sfx)
		return value%ex_life_lost_sfx_list.size()


func update_life_display():
	for i in ex_max_lives:

		var plume = %LifeDisplay.get_node("Feather" + str((i%4 + 1)))
		plume.visible = false
		# Display of the feather according to the number of lives
	
	var lost_lives = ex_max_lives - current_lives
	if lost_lives <= ex_max_lives:
		var plume_animation : AnimationPlayer = %LifeDisplay.get_node("FeatherAnimationPlayer")
		plume_animation.play("HealthLost"+ str(lost_lives))

func handle_game_over() -> void:
	print("GAME OVER")
	reverse_gravity()
	if current_spawn_timer.is_connected("timeout",call_spawn_piece_and_check_victory):
		current_spawn_timer.disconnect("timeout",call_spawn_piece_and_check_victory)
	await get_tree().create_timer(1.0).timeout
	var fade = $ScreenFade
	# makes the black out "fondu au noir"
	fade.modulate.a = 0.0
	fade.visible = true
	var tween = get_tree().create_tween()
	tween.tween_property(fade, "modulate:a", 1.0, 1.0) # noir en 1 seconde
	await tween.finished
	
	
	reset_level()
	# Waits before respawning pieces
	await get_tree().create_timer(1.5).timeout
		# makes the light comes back

	var tween_back = get_tree().create_tween()
	tween_back.tween_property(fade, "modulate:a", 0.0, 1.0)
	await tween_back.finished
	fade.visible = false
	can_lose_life = true

func reset_level():
	# deletes current piece if it exists
	if current_experience and is_instance_valid(current_experience):
		current_experience.queue_free()
	current_index = 0
	current_lives = ex_max_lives
	
	current_balance.queue_free()

	current_balance = balance_scene.instantiate()
	self.add_child(current_balance)
	current_balance.transform = base_balance_transform
	
	var tween = get_tree().create_tween()
	tween.tween_property(subtitle_label, "modulate:a", 0, 0.5) # noir en 1 seconde
	
	update_life_display()
	for child in get_tree().get_nodes_in_group("Experiences"):
		child.queue_free()
	spawn_next_piece()
	update_next_piece_preview()
	


func handle_victory():
	print("VICTORY")
	
	# Met l'ordre du fade très haut pour passer devant tout
	var fade = $ScreenFade
	fade.z_index = 4050
	
		# Fade to black
	fade.modulate.a = 0.0
	fade.visible = true
	var tween = get_tree().create_tween()
	tween.tween_property(fade, "modulate:a", 1.0, 1.0) # fondu au noir
	await tween.finished
	
# Ensuite on affiche le label de victoire
	$VictoryLabel.visible = true
	$VictoryLabel.modulate.a = 0.0  # Commence transparent
	var tween_label = get_tree().create_tween()
	tween_label.tween_property($VictoryLabel, "modulate:a", 1.0, 1.0) # Fade in en 1s
	await tween_label.finished
	
		# Pause 2 secondes pour laisser le joueur savourer
	reverse_gravity()
	await get_tree().create_timer(2.0).timeout
	
	
	#records progression
	var this_level = ex_level_number # adapt according to level
	GlbGameManager.beaten_levels[this_level-1]=true
	GlbGameManager.save_progress()
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://Scenes/UI/map_level_selection.tscn")
	
func _unhandled_input(event):
	if event.is_action_pressed("pause"):
		if get_tree().paused:
			_resume_game()
		else:
			_pause_game()


# Inverse la gravité de tous les objets du groupe "Experiences"
func reverse_gravity():
	# Parcourt tous les nœuds appartenant au groupe "Experiences"
	for child in get_tree().get_nodes_in_group("Experiences"):
		# Cast le nœud en RigidBody2D pour accéder à ses propriétés physiques
		var body := child as RigidBody2D
		body.set_deferred("freeze",false)
		# Modifie l'échelle de la gravité pour inverser sa direction (vers le haut)
		body.gravity_scale = -2
		# Applique une impulsion initiale vers le haut pour donner un effet immédiat
		body.apply_impulse(Vector2.UP)


func _pause_game():
	get_tree().paused = true
	pause_menu.visible = true

func _resume_game():
	get_tree().paused = false
	pause_menu.visible = false

func _on_resume_pressed() -> void:
	_resume_game()

func _on_restart_pressed() -> void:
	reset_level()
	_resume_game()

func _on_quit_pressed() -> void:
	_resume_game()
	get_tree().change_scene_to_file("res://Scenes/UI/map_level_selection.tscn")

func update_next_piece_preview():
	if current_index >= ex_experience_list.size():
		$Cartouche/ExperiencePreview.texture = null
		$Cartouche/ExperienceLabel.text = ""
		return

	var next_scene = ex_experience_list[current_index]
	var next_instance = next_scene.instantiate()
	var sprite = next_instance.get_node_or_null("experience_sprite")

	# Ajout du label
	var scene_name = next_scene.resource_path.get_file().get_basename()
	if experience_keywords.has(scene_name):
		$Cartouche/ExperienceLabel.text = experience_keywords[scene_name]
	else:
		$Cartouche/ExperienceLabel.text = ""

	if sprite and sprite is Sprite2D:
		$Cartouche/ExperiencePreview.texture = sprite.texture
		$Cartouche/ExperiencePreview.material = sprite.material
	else:
		print("'experience_sprite' cannot be found")

	next_instance.queue_free()

func _on_music_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), value)

func _on_sfx_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), value)
