extends RigidBody2D

@export var ex_fall_speed: float = 200.0 # Falling speed when player is in control
@export var ex_horizontal_distance: float = 50 # horizontal distance when pressing Q and D
@export_range(0.0, 1.0) var ex_smoothiness_of_transition := 0.5 # Smoothness of the horizontal movement
@export var ex_gravity: float = 1.0 # How strong is the gravity when you don't controle the experience anymore
@export var ex_time_before_release_control: float = 0.0
signal sig_control_lost

var target_position: Vector2
var is_controlled: bool = true
@onready var self_collider : RigidBody2D = $"."

func _ready() -> void:
	target_position = global_position
	gravity_scale = 0.0
	freeze = true

func _physics_process(delta: float) -> void:
	if is_controlled:
		# horizontal deplacement on input pressed
		if Input.is_action_just_pressed("move_left"):
			target_position.x -= ex_horizontal_distance
		elif Input.is_action_just_pressed("move_right"):
			target_position.x += ex_horizontal_distance
		# Makes the horizontal deplacement smooth
		global_position.x = lerp(global_position.x, target_position.x, ex_smoothiness_of_transition)
		# allows the free vertical fall
		global_position.y += ex_fall_speed * delta

#Need to separate in two functions because Godot doesn't like to change things while changing physics.
func _on_area_2d_body_entered(body: Node) -> void:
	print (body)
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
	print ("release control")
