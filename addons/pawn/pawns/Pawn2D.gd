@tool
@icon("res://addons/pawn/icons/pawn2d.svg")
extends CharacterBody2D
class_name Pawn2D

#region Exposed Variables
var use_navigation: bool
var constant_movement: bool = true
var rotate_when_move_start: bool = true
var max_speed: float
var min_speed: float
var initial_speed: float
#endregion

#region Internal Variables
var direction: Vector2 = Vector2.ZERO;
var speed: float;
var last_face: Vector2
var navigator: PawnNavigator2D
var is_moving = false
#endregion

#region Editor Methods
func _get_configuration_warnings():
	var warnings = []
	var has_navigator = false
	
	for child in get_children():
		if child is PawnNavigator2D:
			has_navigator = true

	if !has_navigator and use_navigation:
		warnings.append("You need to instantiate a PawnNavigator2D")

	if !constant_movement and round(max_speed * 1000) <= 0:
		warnings.append("Without Max Speed your Pawn could lose speed control")

	if !constant_movement and round(min_speed * 1000) <= 0:
		warnings.append("Without Min Speed your Pawn could lose speed control")

	if initial_speed <= 0:
		warnings.append("Without Initial Speed your Pawn will not move")
	elif !constant_movement and max_speed < initial_speed or min_speed > initial_speed:
		warnings.append("Initial speed not match the limits")
	
	if !constant_movement and max_speed <= min_speed:
		warnings.append("Max Speed should be higher than Min Speed")
		
	return warnings
	
func _get_property_list():
	var properties_list = [{
		"name": "Use Navigation",
		"type": TYPE_BOOL,
	}]
	
	if use_navigation:
		properties_list.append({
			"name": "Rotate On Start Movement",
			"type": TYPE_BOOL,
		})
		
	properties_list.append({
		"name": "Constant Movement",
		"type": TYPE_BOOL,
	})
	
	var fields = ["Initial Speed"]
	if !constant_movement:
		fields.append_array(["Max Speed", "Min Speed"])
		
	for field in fields:
		properties_list.append({
			"name": "%s" % field,
			"type": TYPE_FLOAT,
		})
	
	return properties_list
	
func _set(property, value):
	if property == &"Use Navigation":
		use_navigation = value
	elif property == &"Constant Movement":
		constant_movement = value
	elif property == &"Initial Speed":
		initial_speed = value
	elif property == &"Max Speed":
		max_speed = value
	elif property == &"Min Speed":
		min_speed = value
	elif property == &"Rotate On Start Movement":
		rotate_when_move_start = value

	update_configuration_warnings()
	notify_property_list_changed()

func _get(property):
	var values = {
		"Constant Movement": constant_movement,
		"Use Navigation": use_navigation,
		"Initial Speed": initial_speed,
		"Max Speed": max_speed,
		"Min Speed": min_speed,
		"Rotate On Start Movement": rotate_when_move_start,
	}
	
	if values.has(property):
		return values[property]

		
#endregion

signal start_navigation
signal face(pos: Vector2)
signal update_direction(pos: Vector2)
signal add_speed(val: float)


func _add_speed(add_speed: float):
	if constant_movement:
		push_error("Not allowed to change speed with constant movement, change configuration in your Pawn")

	speed = clamp(speed + add_speed, min_speed, max_speed)
	
func _start_navigation():
	navigator.transfer_buffered_to_main()
	if rotate_when_move_start:
		look_at(navigator.target_position)
	
	is_moving = true
	# moving disconnect! and restart
	
func _face(pos: Vector2):
	look_at(pos)
	
func _update_direction(new_direction: Vector2):
	direction = new_direction
	
func _ready():
	speed = initial_speed
	start_navigation.connect(_start_navigation)
	face.connect(_face)
	update_direction.connect(_update_direction)
	add_speed.connect(_add_speed)
	
	for child in get_children():
		if child is PawnNavigator2D:
			navigator = child
	
func _physics_process(delta):
	if Engine.is_editor_hint():
		return
		
	if use_navigation and navigator:
		if !is_moving:
			return

		var nav_direction = navigator.get_next_path_position() - global_position
		direction = nav_direction.normalized()
		
	velocity = direction * delta * 1000 * speed
	move_and_slide()
