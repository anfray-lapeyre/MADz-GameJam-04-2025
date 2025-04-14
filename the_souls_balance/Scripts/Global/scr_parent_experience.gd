extends RigidBody2D

@export var ex_fall_speed: float = 100.0 #falling speed of the experience
@export var ex_horizontal_distance: float = 50 #How much movement from left to right the piece goes when input is pressed
@export_range(0.0,1.0) var ex_smoothiness_of_transition:=0.5  #Between 0 and 1. 1 no smooth, 0 too smooth
@export var ex_gravity: float = 300.0 #gravity when player doesn't control the experience anymore

var target_position: Vector2
var is_controlled: bool = true #Var to allow the player to move the experience and activate gravity

func _ready() -> void: #deactivate gravity when launched
	target_position = global_position
	gravity_scale = 0.0
	freeze = true

func _process(delta: float) -> void: #input fonction
	if is_controlled:
		if Input.is_action_just_pressed("move_left"):
			target_position.x -= ex_horizontal_distance
		elif Input.is_action_just_pressed("move_right"):
			target_position.x += ex_horizontal_distance

		global_position.x = lerp(global_position.x, target_position.x, ex_smoothiness_of_transition) #Horizontal movement smooth
		global_position.y += ex_fall_speed * delta #Constant fall

func _set_control_to_false(): #Makes the player loose control of the experience
	pass
