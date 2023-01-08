extends Node2D

export var DIRECTIONS = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]
export var DIRECTION_IDX = 0
export var TURN_AFTER = 3
export var HAS_FOV = false
export var ZOMBIFY_COOLDOWN = 5

onready var game = get_node("/root/Game")
var map_pos = Vector2(0,0)
var direction = Vector2.RIGHT
var dead = false
var changing_direction = false
var step_counter = 0
var zombify_timeout = 0

onready var indicator = $DirectionIndicator

enum Types {
	boy = 1
	girl = 2
}

enum Modes {
	human = 1,
	zombie = 2
}

export var mode = Modes.human
export var type = Types.boy

var path = []

var FOV = [
	Vector2(1,0),
	Vector2(2,0),
	Vector2(3,0),
	Vector2(4,0)
]

func _ready():	
	set_direction(DIRECTIONS[DIRECTION_IDX])
	jump_to_map_pos(get_map_pos() - Vector2(0,0), 0.1)
	if !HAS_FOV:
		$FOV.hide()
	else:
		$FOV.show()
	if type == Types.girl:
		load_girl_sprites()

func jump():
	if dead: 
		return
	print("MAP POS: " + str(map_pos))
	if zombify_timeout > 0:
		zombify_timeout -= 1
		return
		
	if mode == Modes.zombie:
		update_target_path()
		
	jump_to_map_pos(map_pos + direction)
	
func zombified(by_player = false):
	if mode == Modes.human:
		$AnimationPlayer.stop()
		$AnimationPlayer.play("Zombify")
		mode = Modes.zombie
		zombify_timeout = ZOMBIFY_COOLDOWN
		$FOV.hide()
		game.zombified(self, by_player)
	
func finish_zombification():
	$VisualZombie.scale = $Visual.scale
	$Sfx.get_node("Zombified" + str(randi() % 2 + 1)).play()
	$AnimationPlayer.play("FinishZombification")
	
func is_human():
	return mode == Modes.human
	
func update_target_path():
	path = game.get_nearest_target_path_from(map_pos)
	if path and path.size() > 1:
		var next_pos = path[1]
		set_direction(Vector2(next_pos.x, next_pos.y) - map_pos)
			
func set_direction(new_direction):
	if direction != new_direction:
		changing_direction = true
	direction = new_direction
			
	rotate_according_direction(indicator)

func get_map_pos():
	return Vector2(
		floor(position.x / game.cell_size.x),
		floor(position.y / game.cell_size.y))
	
func jump_to_map_pos(new_map_pos, duration = 0.3):
	if changing_direction:
		rotate_according_direction($FOV)
		changing_direction = false
		
	if mode == Modes.human and HAS_FOV:
		filter_fov(new_map_pos)
	
	if new_map_pos.x < map_pos.x:
		$Visual.scale.x = -0.5
		$VisualZombie.scale.x = -0.5
	if new_map_pos.x > map_pos.x:
		$Visual.scale.x = 0.5
		$VisualZombie.scale.x = 0.5
		
	var new_pos = to_world_pos(new_map_pos)
	$Tween.interpolate_property(self, 'position', position, new_pos, duration, Tween.TRANS_EXPO, Tween.EASE_OUT)
	$Tween.start()
	$AnimationPlayer.play("Jump")
	map_pos = new_map_pos
	
	z_index = new_map_pos.y
		
	if mode == Modes.zombie:
		$ZombifyCheckTimer.start()
	
	if TURN_AFTER > 0:
		step_counter += 1
		if step_counter >= TURN_AFTER:
			step_counter = 0
			next_direction()
	next_safe_direction()
	
func next_safe_direction():
	var iterations = 0
	while !game.is_floor(map_pos + direction) or \
		 (mode == Modes.human && (game.is_occupied_by_player(map_pos + direction) or \
		 game.is_occupied_by_player(map_pos + direction * 2))) or \
		 game.is_occupied_by_zombie(map_pos + direction, self):
		
		iterations += 1
		if iterations > DIRECTIONS.size():
			direction = Vector2(0,0)
			break
		next_direction()
		
func next_direction():
	DIRECTION_IDX += 1
	set_direction(DIRECTIONS[DIRECTION_IDX % DIRECTIONS.size()])
	
func to_world_pos(new_map_pos):
	return new_map_pos * game.cell_size + game.cell_size / 2

func rotate_according_direction(obj):
	match direction:
		Vector2.RIGHT: obj.rotation_degrees = 0
		Vector2.LEFT: obj.rotation_degrees = -180
		Vector2.UP: obj.rotation_degrees = -90
		Vector2.DOWN: obj.rotation_degrees = 90
	
func rotate_vector_according_direction(vec):
	match direction:
		Vector2.RIGHT: return vec.rotated(0)
		Vector2.DOWN: return vec.rotated(PI / 2)
		Vector2.LEFT: return vec.rotated(PI)
		Vector2.UP: return vec.rotated(-PI / 2)
	
func filter_fov(for_map_pos):
	for i in FOV.size():
		var fov = FOV[i]
		var fov_map_pos = for_map_pos + rotate_vector_according_direction(fov)
		
		if game.is_floor(fov_map_pos):
			$FOV.get_node("Indicator0" + str(i + 1)).show()
			if game.is_player(fov_map_pos):
				game.player_is_busted()
		else:
			$FOV.get_node("Indicator0" + str(i + 1)).hide()

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Jump":
		if mode == Modes.human:
			$AnimationPlayer.play("Idle")
		else:
			$AnimationPlayer.play("IdleZombie")
			
	if anim_name == "Zombify":
		finish_zombification()


func load_girl_sprites():
	$Visual/Body/ArmBack.texture = load("res://Components/Enemy/arm_girl.png")
	$Visual/Body/ArmFront.texture = load("res://Components/Enemy/arm_girl.png")
	$Visual/Body/Head.texture = load("res://Components/Enemy/head_girl.png")
	$Visual/Body.texture = load("res://Components/Enemy/body_girl.png")
	$VisualZombie/Body/ArmBack.texture = load("res://Components/Enemy/arm_girl_zombie.png")
	$VisualZombie/Body/ArmFront.texture = load("res://Components/Enemy/arm_girl_zombie.png")
	$VisualZombie/Body/Head.texture = load("res://Components/Enemy/head_girl_zombie.png")
	$VisualZombie/Body.texture = load("res://Components/Enemy/body_girl.png")
	
func _on_ZombifyCheckTimer_timeout():
	var human = game.human_at(map_pos)
	if human:
		$Sfx/Attack.play()
		human.zombified()
