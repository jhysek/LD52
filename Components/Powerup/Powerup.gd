extends Node2D

var map_pos = Vector2(0,0)
onready var game = get_node("/root/Game")

func _ready():
	position = to_world_pos(get_map_pos())

func get_map_pos():
	return Vector2(
		floor(position.x / game.cell_size.x),
		floor(position.y / game.cell_size.y))

func to_world_pos(new_map_pos):
	return new_map_pos * game.cell_size + game.cell_size / 2
