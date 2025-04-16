extends Node2D

var level_size : int = 0 #To makes sure it spawns the right number of pieces (changes in ready function later)
@export var ex_experience_list: Array[PackedScene] #List of experience to spawn (keeps the order)
@export var ex_spawn_position = Vector2(300,-100)
@export var spawn_delay: float = 2.0




func _ready() -> void:
	level_size = ex_experience_list.size() #Get the right array size
	for i in range(level_size) : 
		var spawn = ex_experience_list[i].instantiate()
		add_child(spawn)
