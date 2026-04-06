class_name BossData
extends Resource

class StageData:
	var target_score: int
	var effect: String  # "" = tidak ada efek, "discard_random_2" = efek stage 2
	
	func _init(target: int, fx: String = ""):
		target_score = target
		effect = fx

var display_name: String = ""
var stages: Array = []

func _init(name: String, stage_list: Array):
	display_name = name
	stages = stage_list
