extends Node2D

export var step_duration = 1.0
export var config = {
	superhot=false,
	freestyle=false,
	auto=true
}

var cell_size = Vector2(64, 56)
var used_cells = []

func _ready():
	print(config)
	$Timer.wait_time = step_duration
	if config.auto or config.freestyle:
		$Timer.start()
	var used_cells = $TileMap.get_used_cells()

func player_is_busted():
	print("BUSTED!")
	$Player.busted()

func get_cell(map_pos):
	return $TileMap.get_cell(map_pos.x, map_pos.y)

func is_floor(map_pos):
	return get_cell(map_pos) >= 0

func is_player(map_pos):
	return $Player.map_pos == map_pos

func _on_Timer_timeout():
	if config.auto:
		$Player.jump()
	for enemy in $Enemies.get_children():
		enemy.jump()
		
func jump():
	$Player.jump()
	for enemy in $Enemies.get_children():
		enemy.jump()
