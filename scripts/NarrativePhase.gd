class_name NarrativePhase
extends Resource

class Choice:
	var text: String
	var corruption_delta: int  # positif = naik, negatif = turun
	
	func _init(t: String, delta: int):
		text = t
		corruption_delta = delta

var trigger_at_stage: int = 1  # muncul di stage ke berapa (0-indexed)
var trigger_at_hands: int = 2  # muncul setelah berapa hands di stage itu
var narrative_text: String = ""
var choices: Array = []
var already_triggered: bool = false

func _init(stage: int, hands: int, text: String, choice_list: Array):
	trigger_at_stage = stage
	trigger_at_hands = hands
	narrative_text = text
	choices = choice_list
