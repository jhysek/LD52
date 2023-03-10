extends Node2D

export var DEBUG = false
export var bpm = "90"
export var config = {
	superhot=false,
	freestyle=false,
	auto=true
}
export var disable_blink = true
export var with_tutorial = false

var cell_size = Vector2(64, 56)
var used_cells = []
var floor_plan = null
var map_size = Vector2(0,0)

onready var tilemap = $TileMap
onready var player = $Player
onready var music = $Music/bpm90

var switch_speed_to = false
var time
var changing_time = false
var paused = false
var started = false
var finished = false
var minx = 999
var miny = 999


const SPEEDS = {
	"60": 1,
	"90": 60 / 90.0,
	"120": 0.5
}

var beat_duration = 0.5
var next_beat_at  = 0

func _ready():
	used_cells = tilemap.get_used_cells()
	var first_cell = used_cells[0]
	var last_cell = used_cells[used_cells.size() - 1]
	
	map_size = get_map_size(used_cells)
	#map_size = Vector2(last_cell.x - first_cell.x, last_cell.y - first_cell.y)
	
	beat_duration = SPEEDS[bpm]
	music = $Music.get_node("bpm" + str(bpm))
	
	$BrainIndicator.initialize($Humans.get_child_count())
	
	started = false
	generate_floor_plan()
	if with_tutorial:
		$SpaceToStart.hide()
		$Tutorial/AnimationPlayer.play("Tutorial")
	else:
		$Tutorial/AnimationPlayer.play("WaitForStart")
		
	set_process_input(true)
		
func get_map_size(cells):
	minx = 999
	var maxx = -999
	miny = 999
	var maxy = -999
	for cell in cells:
		if cell.x < minx:
			minx = cell.x 
		if cell.x > maxx:
			maxx = cell.x 
		if cell.y < miny:
			miny = cell.y 
		if cell.y > maxy: 
			maxy = cell.y  
	
	return Vector2(maxx - minx + 1, maxy - miny + 1)
		
func _input(event):
	if !started and event is InputEventKey and event.pressed:
		if !with_tutorial:
			start_game()
		
	if started and event is InputEventKey and event.is_action_pressed('ui_cancel'):
		if !paused:
			paused = true
			music.set_stream_paused(true)
			$PauseMenu.show()
		else:
			paused = false
			$PauseMenu.hide()
			music.set_stream_paused(false)
		
	if DEBUG:
		if event is InputEventKey and event.is_action_pressed('ui_debug'):
			_on_Timer_timeout()

		if Input.is_action_just_pressed("ui_debug"):
			if bpm == "60":
				switch_speed_to = "90"
				return
			
			if bpm == "90":
				switch_speed_to = "120"
				return

func start_game():
	started = true
	$Tutorial/AnimationPlayer.play_backwards("WaitForStart")
	Music.stop()
	if !DEBUG and (config.auto or config.freestyle):
		next_beat_at = beat_duration
		music.play()
		set_process(true)

func restart_level():
	LevelSwitcher.restart_level()

func _process(delta):	
	if paused or !started:
		return
			
	var oldtime = time
	time = music.get_playback_position() + AudioServer.get_time_since_last_mix()
	time -= AudioServer.get_output_latency() # - 0.01
	#print("TIME: " + str(oldtime) + " => " + str(time))
	
	if time > next_beat_at:
		#print("TIME FOR NEXT BEAT: " + str(time) + " > " + str(next_beat_at))
		next_beat_at += beat_duration
					
		_on_Timer_timeout()
		if switch_speed_to:
			switch_speed(switch_speed_to, time)
			switch_speed_to = false

					
func switch_speed(new_speed, time):
	changing_time = true
	print("TIME: " + str(time))
	var time_convert_ratio = SPEEDS[new_speed] / beat_duration 
	print("NEW MUSIC POS: " + str(time_convert_ratio * time))
	beat_duration = SPEEDS[new_speed]
	bpm = new_speed
	music.stop()
	music = $Music.get_node("bpm" + str(new_speed))
	music.play(time_convert_ratio * time)
	changing_time = true
	
	next_beat_at = time_convert_ratio * time + beat_duration
	time = time_convert_ratio * time 
	changing_time = false
	
func player_is_busted():
	$Player.busted()

func get_cell(map_pos):
	return $TileMap.get_cellv(map_pos)
	
func get_cell_xy(x, y):
	return tilemap.get_cell(x, y)

func is_floor(map_pos):
	return accessible_cell(get_cell(map_pos))
	
func accessible_cell(cell_code):
  return cell_code >= 0

func map_pos_code(map_pos):
  return str(map_pos.x) + "x" + str(map_pos.y)

func get_cell_id(x, y):
  return x * map_size.x + y

func get_nearest_target_path_from(start_pos):
	var result = null
	var shortest_path  = 999
	
	for human in $Humans.get_children():
		var path = get_nearest_path(start_pos, human.map_pos)
		if path.size() < shortest_path:
			shortest_path = path.size()
			result = path
	return result

func add_line(start, end):
	var line = Line2D.new()
	add_child(line)
	line.points.append(start)
	line.points.append(end)

func generate_floor_plan():
	if !floor_plan:
		floor_plan = AStar.new()
	else:
		floor_plan.clear()

  # Add nodes
	for x in range(map_size.x + 1):
		for y in range(map_size.y + 1):
			if accessible_cell(get_cell_xy(x, y)):
				floor_plan.add_point(get_cell_id(x, y), Vector3(x, y, 0))

  # Add connections
	for xx in range(map_size.x):
		for yy in range(map_size.y):
			var x = minx + xx
			var y = miny + yy
			var cell_id = get_cell_id(x, y)
			if floor_plan.has_point(cell_id):
				# get neighbours
				if accessible_cell(get_cell_xy(x + 1, y)):
					floor_plan.connect_points(cell_id, get_cell_id(x+1, y))
				if accessible_cell(get_cell_xy(x, y + 1)):
					floor_plan.connect_points(cell_id, get_cell_id(x, y + 1))
				if accessible_cell(get_cell_xy(x - 1, y)):
					floor_plan.connect_points(cell_id, get_cell_id(x-1, y))
				if accessible_cell(get_cell_xy(x, y - 1)):
					floor_plan.connect_points(cell_id, get_cell_id(x, y - 1))

func get_nearest_path(from, to):
	return floor_plan.get_point_path(get_cell_id(from.x, from.y), get_cell_id(to.x, to.y))

func is_player(map_pos):
	return $Player.map_pos == map_pos

func _on_Timer_timeout():
	if !disable_blink:
		switch_floor_cells()
	if config.auto:
		$Player.jump()
	for human in $Humans.get_children():
		human.jump()
	for zombie in $Zombies.get_children():
		zombie.jump()
		
func jump():
	$Player.jump()
	for human in $Humans.get_children():
		human.jump()
	for zombie in $Zombies.get_children():
		zombie.jump()
	generate_floor_plan()
	
func zombified(human, by_me = false):
	if by_me:
		$BrainIndicator.brain_harvested()
		$BrainIndicator.animate_brain_harvest(human.position)
	else:
		$BrainIndicator.brain_lost()
		
	if $BrainIndicator.all_harvested():
		finished = true
		$FinishTimeout.start()

	var parent = human.get_parent()
	parent.remove_child(human)
	$Zombies.add_child(human)
	
func is_occupied_by_human(map_pos):
	for human in $Humans.get_children():
		if human.map_pos == map_pos:
			return true
	return false
	
func human_at(map_pos):
	for human in $Humans.get_children():
		if human.map_pos == map_pos:
			return human
	return false
	
func is_occupied_by_zombie(map_pos, me = null):
	for zombie in $Zombies.get_children():
		if zombie.map_pos == map_pos and zombie != me:
			return true
	return false
	
func is_occupied_by_player(map_pos):
	return player and player.map_pos == map_pos

func _on_bpm90_finished():
	if !finished:
		music.play()
		next_beat_at = beat_duration

func _on_bpm60_finished():
	if !finished:
		music.play()
		next_beat_at = beat_duration

func _on_bpm120_finished():
	if !finished:
		music.play()
		next_beat_at = beat_duration

func switch_floor_cells():
	for cell in tilemap.get_used_cells():
		if tilemap.get_cellv(cell) == 1:
			tilemap.set_cellv(cell, 2)
		elif tilemap.get_cellv(cell) == 2:
			tilemap.set_cellv(cell, 1)
		
func _on_Quit_pressed():
	get_tree().change_scene("res://Scenes/Menu.tscn")

func _on_Start_pressed():
	LevelSwitcher.next_level()

func _on_FinishTimeout_timeout():
	var time_convert_ratio = SPEEDS["120"] / beat_duration 
	beat_duration = SPEEDS["120"]
	music.stop()
	$Music/bpm60.stop()
	$Music/bpm90.stop()
	$Music/bpm120.play(time_convert_ratio * time)
	
	paused = true
	if $BrainIndicator.gained_all():
		$LevelFinished.show()
	else:
		$Music/LevelFinished.stream = load("res://Assets/level_failed.mp3")
		$Music/LevelFinished.play()
		$LevelFailed.show()
		
	for zombie in $Zombies.get_children():
		zombie.get_node("DirectionIndicator").hide()
		zombie.get_node("AnimationPlayer").play("IdleZombie")
	$Player.get_node("DirectionIndicator").hide()

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Tutorial":
		start_game()


func _on_HintTimer_timeout():
	$Hint/AnimationPlayer.play("FadeIn")
