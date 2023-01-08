extends Node2D

onready var game = get_node("/root/Game")

var map_pos = Vector2(0,0)
var dash_length = 2
var direction = Vector2.RIGHT
var dashing = false
var dead = false

onready var superhot_style = false
onready var free_style = false

func _ready():
	jump_to_map_pos(get_map_pos() - Vector2(1, 0), 0.1)
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
			if game.is_floor(map_pos + direction * 2):
				dash()
			else:
				print("CANNOT DASH, NOT SAFE...")
	
	next_safe_direction()
			
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
	if new_map_pos.x < map_pos.x:
		$Visual.scale.x = -0.5
	if new_map_pos.x > map_pos.x:
		$Visual.scale.x = 0.5
	$AnimationPlayer.play("Jump")
	$Tween.interpolate_property(self, 'position', position, new_pos, duration, Tween.TRANS_EXPO, Tween.EASE_OUT)
	$Tween.start()

	map_pos = new_map_pos
	$ZombifyCheckTimer.start()
	next_safe_direction()
		
func next_safe_direction():
	var iterations = 0
	while !game.is_floor(map_pos + direction): 
		next_direction()		
		iterations += 1
		if iterations > 2:
			direction = Vector2(0,0)
			break
		
func next_direction():
	direction = direction.rotated(PI)
	direction = Vector2(int(direction.x), int(direction.y))
	rotate_according_direction($DirectionIndicator)
	
func to_world_pos(new_map_pos):
	return new_map_pos * game.cell_size + game.cell_size / 2
	
func rotate_according_direction(obj):
	match direction:
		Vector2.RIGHT: obj.rotation_degrees = 0
		Vector2.LEFT: obj.rotation_degrees = -180
		Vector2.UP: obj.rotation_degrees = -90
		Vector2.DOWN: obj.rotation_degrees = 90

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Jump":
		$AnimationPlayer.play("Idle")

func _on_ZombifyCheckTimer_timeout():
	var human = game.human_at(map_pos)
	if human:
		human.zombified(true)
		
