extends Node2D

var level_size : int = 0 #To makes sure it spawns the right number of pieces (changes in ready function later)
@export var ex_experience_list: Array[PackedScene] #List of experience to spawn (keeps the order)
@export var ex_spawn_position = Vector2(300,-100)
@export var ex_spawn_delay: float = 2.0
@export var ex_max_lives: int = 3
@export var ex_hurt_cooldown_time: float = 1.5
@export var ex_gravity_reverse_duration: float = 3.0

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
		current_experience.sig_control_lost.connect(_on_piece_lost_control)

func _on_piece_lost_control(): #Disconnects the signal after it's send so two pieces don't spawn at the same time
	if current_experience.has_signal("sig_control_lost"):
		current_experience.sig_control_lost.disconnect(_on_piece_lost_control)
	
	await get_tree().create_timer(ex_spawn_delay).timeout
	spawn_next_piece()
	
func _on_dead_zone_body_entered(body: Node2D) -> void: #connects with dead zone
	if not body is RigidBody2D:
		return
	if can_lose_life:
		lose_life()
		
func lose_life() -> void: #func when you loose life
	current_lives -= 1
	can_lose_life = false
	print("Vie perdue ! Il en reste : ", current_lives)
	# Screenshake
	start_screenshake()
	# feather display change
	update_life_display()
	# Cooldown
	await get_tree().create_timer(ex_hurt_cooldown_time).timeout
	can_lose_life = true
	#Game over
	if current_lives <= 0:
		await handle_game_over()

func start_screenshake():
	var original_pos = position
	var tween = get_tree().create_tween()
	tween.tween_property(self, "position", original_pos + Vector2(10, 0), 0.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position", original_pos - Vector2(10, 0), 0.05)
	tween.tween_property(self, "position", original_pos, 0.05)
	
func update_life_display():
	for i in ex_max_lives:
		var plume = get_node("LifeDisplay").get_node("Feather" + str(i + 1))
		plume.modulate = Color(1, 1, 1, 1) if i < current_lives else Color(1, 1, 1, 0.2)
		
func handle_game_over() -> void:
	print("GAME OVER")
	# Revert gravity
	PhysicsServer2D.area_set_param(get_world_2d().space, PhysicsServer2D.AREA_PARAM_GRAVITY_VECTOR, Vector2.UP)
	PhysicsServer2D.area_set_param(get_world_2d().space, PhysicsServer2D.AREA_PARAM_GRAVITY, 500) #500 is the gravity strength
	# Await chaos
	await get_tree().create_timer(ex_gravity_reverse_duration).timeout
	# Puts it back together
	PhysicsServer2D.area_set_param(get_world_2d().space, PhysicsServer2D.AREA_PARAM_GRAVITY_VECTOR, Vector2.DOWN)
	# Reset the level
	reset_level()
	# Waits before respawning pieces
	await get_tree().create_timer(1.5).timeout
	
func reset_level():
	current_index = 0
	current_lives = ex_max_lives
	update_life_display()
	for child in get_children():
		if child.name.begins_with("obj_experience"): # ou autre préfixe commun
			child.queue_free()
	spawn_next_piece()
