extends Node2D

var cell_size = Vector2(64, 64)
var used_cells = []

func _ready():
	var used_cells = $TileMap.get_used_cells()

func get_cell(map_pos):
	return $TileMap.get_cell(map_pos.x, map_pos.y)

func _on_Timer_timeout():
	$Player.jump()
	for enemy in $Enemies.get_children():
		enemy.jump()
