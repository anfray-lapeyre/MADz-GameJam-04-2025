extends RigidBody2D

@export var ex_fall_speed: float = 200.0 # Falling speed when player is in control
@export var ex_cell_size: float = 32.0 # size of a cell from the grid when moving horizontally (where does the piece stops)
@export var ex_move_repeat_delay: float = 0.1 # Delay for spamming inputs, and gives horizontal speed
@export var ex_gravity: float = 1.0 # How strong is the gravity when you don't controle the experience anymore
@export var ex_time_before_release_control: float = 0.0
signal sig_control_lost

var current_rotation_state := 0 # 0, 1, 2, 3 for the 4 directions
var target_position: Vector2
var is_controlled: bool = true
@onready var self_collider : RigidBody2D = $"."
@onready var light_beam : Sprite2D = $light_beam

var move_left_timer := 0.0
var move_right_timer := 0.0
var has_moved_left := false
var has_moved_right := false

func _ready() -> void:
	target_position = global_position
	gravity_scale = 0.0
	freeze = true
	_update_light_beam()

func _physics_process(delta: float) -> void:
	if is_controlled:
		_handle_horizontal_input(delta) 
		
		if Input.is_action_just_pressed("rotate_left"):
			_rotate_piece(-1)
		elif Input.is_action_just_pressed("rotate_right"):
			_rotate_piece(1)
		# allows the free vertical fall
		global_position.y += ex_fall_speed * delta
		global_position.x = target_position.x
		
		_update_light_beam()
		

func _handle_horizontal_input(delta: float) -> void: #Makes the grid-like movement
	if Input.is_action_pressed("move_left"):
		move_left_timer -= delta
		if !has_moved_left or move_left_timer <= 0.0:
			target_position.x -= ex_cell_size
			target_position.x = _snap_to_step(target_position.x)
			move_left_timer = ex_move_repeat_delay
			has_moved_left = true
	else:
			move_left_timer = 0.0
			has_moved_left = false
			
	if Input.is_action_pressed("move_right"):
		move_right_timer -= delta
		if !has_moved_right or move_right_timer <= 0.0:
			target_position.x += ex_cell_size
			target_position.x = _snap_to_step(target_position.x)
			move_right_timer = ex_move_repeat_delay
			has_moved_right = true
	else:
			move_right_timer = 0.0
			has_moved_right = false
			
# function to align exp on the grid
func _snap_to_step(x: float) -> float:
	return round(x / ex_cell_size) * ex_cell_size

#Need to separate in two functions because Godot doesn't like to change things while changing physics.
func _on_area_2d_body_entered(body: Node) -> void:
	if body == self_collider:
		return
	if is_controlled :
		call_deferred("_release_control") #To avoid everything happening all at once and yeeting the experiences

func _release_control(): #function to make the player loose control of the pieces
	if is_controlled == false:
		return
	await get_tree().create_timer(ex_time_before_release_control).timeout
	is_controlled = false
	freeze = false
	sig_control_lost.emit() #send a signal to game level
	gravity_scale = ex_gravity
	light_beam.hide()
	
func _rotate_piece(direction: int): 
	current_rotation_state = (current_rotation_state + direction) % 4
	if current_rotation_state < 0:
		current_rotation_state += 4
	rotation_degrees = current_rotation_state * 90
	_update_light_beam()
	
	# updates the position of the beam and its size
func _update_light_beam():
	var beam := $light_beam
	var sprite := $experience_sprite
	if not beam or not sprite or not sprite.texture:
		return
	# blocks rotation when experience is rotating
	beam.rotation = -rotation
	# follows horizontal position of the experience
	beam.global_position.x = global_position.x
	# Mettre le beam tout en bas de l’écran (ajuste si besoin)
	beam.global_position.y = 0  # tu peux ajuster ce Y selon ton niveau
	# Getting the right width
	var tex_size: Vector2 = sprite.texture.get_size()
	var scale: Vector2 = sprite.scale
	var width: float = tex_size.x * scale.x if int(rotation_degrees) % 180 == 0 else tex_size.y * scale.y
	# Apply Size
	light_beam.scale.x = width / light_beam.texture.get_size().x
	# Gives the right position
	var beam_pos: Vector2 = light_beam.position
	beam_pos.x = 0 # centering on experience
	light_beam.position = beam_pos
	# cancels rotation herited
	light_beam.rotation_degrees = -rotation_degrees
	# Adatps scale of beam
	if beam.texture:
		beam.scale.x = width / beam.texture.get_size().x
	
