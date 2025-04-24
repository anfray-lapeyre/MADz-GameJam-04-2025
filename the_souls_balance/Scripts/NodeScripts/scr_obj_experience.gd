extends RigidBody2D

enum PowerType{
	NONE,
	GHOST,
	SLIME,
	VOID,
}

@export var power_type : PowerType = PowerType.NONE
var is_power_in_use :bool = false; #Only used for slime
@export var ex_base_fall_speed: float = 300.0 # Falling speed when player is in control
@export var ex_fast_fall_speed: float = 1000.0 #Falling speed when player presses down
var current_fall_speed:float = ex_base_fall_speed #Actual current fall speed, either base or fast

@export var ex_should_use_raycast_collisions :bool=true

@export var ex_cell_size: float = 32.0 # size of a cell from the grid when moving horizontally (where does the piece stops)
@export var ex_move_repeat_delay: float = 0.1 # Delay for spamming inputs, and gives horizontal speed
@export var ex_gravity: float = 1.0 # How strong is the gravity when you don't controle the experience anymore
@export var ex_time_before_release_control: float = 0.0
signal sig_control_lost

@export var ex_ghost_material:Material;

var current_rotation_state := 0 # 0, 1, 2, 3 for the 4 directions
var target_position: Vector2
var is_controlled: bool = true
@onready var self_collider : RigidBody2D = $"."
@onready var light_beam : Sprite2D = $light_beam
@onready var beam := $light_beam
@onready var sprite := $experience_sprite

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
		_handle_vertical_input(delta)
		if Input.is_action_just_pressed("rotate_left"):
			_rotate_piece(-1)
		elif Input.is_action_just_pressed("rotate_right"):
			_rotate_piece(1)
		
		if ex_should_use_raycast_collisions == true:
			var direction =Vector2.ZERO #Vector2((global_position.x-target_position.x)*-1,(global_position.y-target_position.y)*-5)
			direction.y = ex_base_fall_speed * delta*3
			
			# allows the free vertical fall
			var hits := trace_custom_polygon($experience_collider,global_position + direction)
			if hits.size() > 0:
				print(hits)
				if is_controlled :
					call_deferred("_release_control") #To avoid everything happening all at once and yeeting the experiences
					return
					
			direction = Vector2.ZERO
			direction.x = (global_position.x-target_position.x)*-2
			hits = trace_custom_polygon($experience_collider,global_position + direction)
			if hits.size() > 0:
				target_position.x=global_position.x

		global_position.y = target_position.y 
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

#Handle the input to go down faster
func _handle_vertical_input(_delta:float) -> void:
	if Input.is_action_pressed("move_down"):
		current_fall_speed = ex_fast_fall_speed
	else:
		current_fall_speed = ex_base_fall_speed
	target_position.y +=current_fall_speed * _delta
		
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
	_use_power()
	light_beam.hide()
	
func _use_power():
	await get_tree().create_timer(0.5).timeout
	match power_type:
		PowerType.GHOST:
			for child in $ghost_area.get_overlapping_bodies():
				if (child).is_in_group("Experiences") && child != self:
					(child as RigidBody2D).freeze=true
					for grandchild in child.get_children():
						if grandchild is Sprite2D:
							(grandchild as Sprite2D).material = ex_ghost_material
			queue_free()
		PowerType.SLIME:
			is_power_in_use=true;
			self.linear_damp = 2.0
		PowerType.VOID:
			for child in $void_area.get_overlapping_bodies():
				if (child).is_in_group("Experiences") && child != self:
					child.queue_free()
			$void_area.queue_free()
	
func _rotate_piece(direction: int): 
	current_rotation_state = (current_rotation_state + direction) % 4
	if current_rotation_state < 0:
		current_rotation_state += 4
	rotation_degrees = current_rotation_state * 90
	_update_light_beam()
	
	# updates the position of the beam and its size
func _update_light_beam():
	if not beam or not sprite or not sprite.texture:
		return
	# blocks rotation when experience is rotating
	beam.rotation = -rotation
	# follows horizontal position of the experience
	beam.global_position.x = global_position.x
	# Mettre le beam tout en bas de l’écran (ajuste si besoin)
	beam.global_position.y = 0  # tu peux ajuster ce Y selon ton niveau
	# Getting the right width
	var tex_size: Vector2 = (get_polygon_size($experience_collider.polygon)) #Getting the collider size to adapt the beam
	var beam_scale: Vector2 = $experience_collider.scale*1.2 #Added a 1.2 multiplier to compensate for the coutour of the texture
	var width: float = tex_size.x * beam_scale.x if int(rotation_degrees) % 180 == 0 else tex_size.y * beam_scale.y
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
	
	
# Returns the bounding extents of a set of 2D points as a Vector4.
# The returned Vector4 contains: (minX, minY, maxX, maxY)
func get_pvector_extents(p: PackedVector2Array) -> Vector4:
	# Initialize min and max values with the first point's coordinates
	var minX: float = p[0].x
	var maxX: float = p[0].x 
	var minY: float = p[0].y 
	var maxY: float = p[0].y

	# Iterate through all points to find the min and max extents
	for v in p:
		if v.x < minX: 
			minX = v.x
		if v.x > maxX: 
			maxX = v.x
		if v.y < minY: 
			minY = v.y
		if v.y > maxY: 
			maxY = v.y

	# Return the bounds as a Vector4: (minX, minY, maxX, maxY)
	return Vector4(minX, minY, maxX, maxY)

# Calculates the size of a polygon from its set of 2D points.
# Returns the width and height as a Vector2.
func get_polygon_size(p: PackedVector2Array) -> Vector2:
	# Get the bounding extents of the polygon
	var v: Vector4 = get_pvector_extents(p)

	# Create a Rect2 from the extents to compute the size
	var r: Rect2 = Rect2(v.x, v.y, abs(v.z - v.x), abs(v.w - v.y))

	# Return the size (width, height) of the bounding rectangle
	return r.size




func _on_slime_area_area_entered(area: Area2D) -> void:
	if !is_power_in_use:
		return
	var body = area.get_parent()
	if body != self && body is RigidBody2D && body.is_in_group("Experiences"):
		(body as RigidBody2D).linear_damp=20.0
		body._on_area_2d_body_entered(self)


func _on_slime_area_area_exited(area: Area2D) -> void:
	var body = area.get_parent()
	if body != self && body is RigidBody2D && body.is_in_group("Experiences"):
		(body as RigidBody2D).linear_damp=0.0
		body._on_area_2d_body_entered(self)

func trace_custom_polygon(polygon: CollisionPolygon2D, _position: Vector2, _rotation: float = 0.0, _ignore_self=true) -> Array:
	if !polygon:
		return []

	var space := get_world_2d().direct_space_state
	var _transform := Transform2D(polygon.global_rotation + _rotation, polygon.global_scale ,polygon.skew,_position)

	# Get polygon points
	var points := polygon.polygon
	var hit_points := []

	# Optional exclusion
	var exclude = [self.get_rid()] if _ignore_self else []

	# For each edge in the polygon, cast a ray
	for i in points.size():
		var local_a := points[i]
		var local_b := points[(i + 1) % points.size()]

		var global_a := _transform * local_a
		var global_b := _transform * local_b

		# Set up the query for raycast
		var query := PhysicsRayQueryParameters2D.new()
		query.from = global_a
		query.to = global_b
		query.exclude = exclude

		# Perform the ray intersection query
		var result = space.intersect_ray(query)

		if result:
			hit_points.append({
				"position": result.position,
				"normal": result.normal,
				"collider": result.collider
			})

	return hit_points
	
	
func get_closest_collision(result: Array, origin: Vector2) -> Dictionary:
	var closest = null
	var closest_dist := INF

	for hit in result:
		if hit.has("position"):
			var dist = origin.distance_to(hit.position)
			if dist < closest_dist:
				closest = hit
				closest_dist = dist
	
	# If no collision was found, return an empty dictionary instead of null
	return closest if closest != null else {}
