extends Node2D

var Brain = preload("res://Components/BrainIndicator/Brain.tscn")
var total = 0
var gained = 0
var lost = 0

func initialize(new_total):
	total = new_total
	for i in range(total):
		var brain = Brain.instance()
		brain.name = "Brain" + str(i + 1)
		add_child(brain)
		brain.position = Vector2(296 + i * 72, 0)

func gained_all():
	return gained == total

func brain_harvested():
	if !gained_all():
		gained += 1
		var brain = get_node("Brain" + str(gained))
		brain.activate()

func brain_lost():
	lost += 1
	
func all_harvested():
	return  gained + lost >= total
	
func animate_brain_harvest(from_world_position):
	var brain = Brain.instance()
	brain.name = "TemporaryBrain"
	brain.modulate = Color("ffffff")
	get_parent().add_child(brain)
	brain.position = from_world_position
	brain.tween_to(global_position + Vector2(296 + (gained - 1) * 72, 0))
	
