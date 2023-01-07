extends Node2D

onready var game = get_node("/root/Game")
var map_pos
var dash_length = 2
var direction = Vector2.RIGHT
var dashing = false
var dead = false

onready var superhot_style = false
onready var free_style = false

func _ready():
	jump_to_map_pos(get_map_pos(), 0.1)
	set_process_input(true)

func busted():
	dead = true
	$DirectionIndicator.hide()

func _input(event):
	if event is InputEventKey and event.is_action_pressed('ui_left'):
		direction = Vector2.LEFT
		$DirectionIndicator.rotation_degrees = -180
		if game.config.superhot:
			game.jump()
		if game.config.freestyle:
			jump()
		
	if event is InputEventKey and event.is_action_pressed('ui_right'):
		direction = Vector2.RIGHT
		$DirectionIndicator.rotation_degrees = 0
		if game.config.superhot:
			game.jump()
		if game.config.freestyle:
			jump()
		
	if event is InputEventKey and event.is_action_pressed('ui_up'):
		direction = Vector2.UP
		$DirectionIndicator.rotation_degrees = -90
		if game.config.superhot:
			game.jump()
		if game.config.freestyle:
			jump()
		
	if event is InputEventKey and event.is_action_pressed('ui_down'):
		direction = Vector2.DOWN
		$DirectionIndicator.rotation_degrees = 90
		if game.config.superhot:
			game.jump()
		if game.config.freestyle:
			jump()
		
	if event is InputEventKey and event.is_action_pressed('ui_accept'):
		if !dashing:
			dash()
			
func dash():
	dashing = true
	jump_to_map_pos(map_pos + direction * dash_length)
			
func jump():
	if dead: 
		return
		
	if !dashing:
		jump_to_map_pos(map_pos + direction)
	else:
		dashing = false
		
func get_map_pos():
	return Vector2(
		floor(position.x / game.cell_size.x),
		floor(position.y / game.cell_size.y))
	
func jump_to_map_pos(new_map_pos, duration = 0.2):
	var new_pos = to_world_pos(new_map_pos)
	$Tween.interpolate_property(self, 'position', position, new_pos, duration, Tween.TRANS_EXPO, Tween.EASE_OUT)
	$Tween.start()
	map_pos = new_map_pos
	
func to_world_pos(map_pos):
	return map_pos * game.cell_size + game.cell_size / 2
