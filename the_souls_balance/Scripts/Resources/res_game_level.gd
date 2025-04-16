extends Node2D

var level_size : int = 0 #To makes sure it spawns the right number of pieces (changes in ready function later)
@export var ex_experience_list: Array[PackedScene] #List of experience to spawn (keeps the order)
@export var ex_spawn_position = Vector2(300,-100)
@export var spawn_delay: float = 2.0

var current_index: int = 0 #helps to know at which experience we're at in the list.
var current_experience: Node = null #references the current experience, to connect signals.

func _ready() -> void:
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
	
	await get_tree().create_timer(spawn_delay).timeout
	spawn_next_piece()
