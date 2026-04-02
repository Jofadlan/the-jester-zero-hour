extends Node

var deck_manager: DeckManager
var jp_manager: JPManager
var evaluator: HandEvaluator

func _ready():
	deck_manager = DeckManager.new()
	add_child(deck_manager)
	
	jp_manager = JPManager.new()
	add_child(jp_manager)
	jp_manager.reset_for_duel(0)
	
	evaluator = HandEvaluator.new()
	
	# Test: deal hand dan evaluate 5 kartu pertama
	deck_manager.deal_hand()
	var hand = deck_manager.hand
	
	print("=== HAND DEALT ===")
	for card in hand:
		print(card.get_display_name(), " (chips: ", card.get_chip_value(), ")")
	
	print("\n=== PLAY FIRST 5 ===")
	var played = hand.slice(0, 5)
	var result = evaluator.evaluate(played)
	print("Hand type: ", result["hand_type"])
	print("Chips: ", result["chips"])
	print("Mult: ", result["mult"], "x")
	print("Score: ", result["score"])
	print("JP: ", jp_manager.jp_current, "/", jp_manager.jp_max)
