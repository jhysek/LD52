extends Node2D

export var DIRECTIONS = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]
export var DIRECTION_IDX = 0

onready var game = get_node("/root/Game")
var map_pos
var direction = Vector2.RIGHT
var dead = false
var changing_direction = false
onready var indicator = $DirectionIndicator

var FOV = [
	Vector2(1,0),
	Vector2(2,0),
	Vector2(3,0),
	Vector2(4,0)
]

func _ready():
	set_direction(DIRECTIONS[DIRECTION_IDX])
	jump_to_map_pos(get_map_pos(), 0.1)

func jump():
	if dead: 
		return
	jump_to_map_pos(map_pos + direction)
		
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
		
	var new_pos = to_world_pos(new_map_pos)
	$Tween.interpolate_property(self, 'position', position, new_pos, duration, Tween.TRANS_EXPO, Tween.EASE_OUT)
	$Tween.start()
	map_pos = new_map_pos
	
	filter_fov()
	
	var next_cell = game.get_cell(map_pos + direction)
	while next_cell < 0:
		next_direction()
		next_cell = game.get_cell(map_pos + direction)
	
func next_direction():
	DIRECTION_IDX += 1
	set_direction(DIRECTIONS[DIRECTION_IDX % DIRECTIONS.size()])
	
func to_world_pos(map_pos):
	return map_pos * game.cell_size + game.cell_size / 2

func rotate_according_direction(obj):
	match direction:
		Vector2.RIGHT: obj.rotation_degrees = 0
		Vector2.LEFT: obj.rotation_degrees = -180
		Vector2.UP: obj.rotation_degrees = -90
		Vector2.DOWN: obj.rotation_degrees = 90
	
func filter_fov():
	for i in FOV.size():
		pass
