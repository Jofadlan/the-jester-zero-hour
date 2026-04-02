extends Node2D

@onready var score_label = $UI/ScoreLabel
@onready var target_label = $UI/TargetLabel
@onready var jp_label = $UI/JPLabel
@onready var hand_type_label = $UI/HandTypeLabel
@onready var hand_container = $UI/HandContainer
@onready var btn_play = $UI/BtnPlayHand
@onready var btn_discard = $UI/BtnDiscard
@onready var overlay = $UI/Overlay
@onready var overlay_title = $UI/Overlay/VBoxContainer/Title
@onready var overlay_sub = $UI/Overlay/VBoxContainer/Sub
@onready var btn_continue = $UI/Overlay/VBoxContainer/BtnContinue
@onready var btn_stop = $UI/Overlay/VBoxContainer/BtnStop
@onready var deck_manager = $Managers/DeckManager
@onready var jp_manager = $Managers/JPManager

var evaluator: HandEvaluator
var selected_cards: Array[Card] = []
var current_score: int = 0
var target_score: int = 300
var hands_played: int = 0
var max_hands: int = 4
var stage: int = 1

const HAND_NAMES = {
	0: "High Card", 1: "Pair", 2: "Two Pair",
	3: "Three of a Kind", 4: "Straight", 5: "Flush",
	6: "Full House", 7: "Four of a Kind",
	8: "Straight Flush", 9: "Royal Flush"
}

func _ready():
	evaluator = HandEvaluator.new()
	jp_manager.jp_changed.connect(_on_jp_changed)
	jp_manager.reset_for_duel(0)

	btn_play.pressed.connect(_on_play_pressed)
	btn_discard.pressed.connect(_on_discard_pressed)
	btn_continue.pressed.connect(_on_continue_pressed)
	btn_stop.pressed.connect(_on_stop_pressed)

	btn_play.disabled = true
	btn_discard.disabled = true
	overlay.visible = false

	_update_ui()
	_deal_hand()

func _deal_hand():
	deck_manager.deal_hand()
	selected_cards.clear()
	_render_hand()
	_update_buttons()

func _render_hand():
	for child in hand_container.get_children():
		child.queue_free()
	for card in deck_manager.hand:
		var btn = Button.new()
		btn.text = card.get_display_name()
		btn.custom_minimum_size = Vector2(60, 90)
		btn.pressed.connect(_on_card_pressed.bind(card, btn))
		hand_container.add_child(btn)

func _on_card_pressed(card: Card, btn: Button):
	if card in selected_cards:
		selected_cards.erase(card)
		btn.modulate = Color.WHITE
	else:
		if selected_cards.size() < 5:
			selected_cards.append(card)
			btn.modulate = Color(1.5, 1.2, 0.3)
	_update_buttons()
	if selected_cards.size() > 0:
		var result = evaluator.evaluate(selected_cards)
		hand_type_label.text = HAND_NAMES[result["hand_type"]] + \
			"  —  " + str(result["chips"]) + " × " + str(result["mult"])

func _on_play_pressed():
	if selected_cards.is_empty():
		return
	var result = evaluator.evaluate(selected_cards)
	current_score += result["score"]
	hands_played += 1
	hand_type_label.text = HAND_NAMES[result["hand_type"]] + \
		"  +  " + str(result["score"]) + " pts"
	
	# Hapus kartu yang dimainkan dari hand, ganti dengan kartu baru
	for card in selected_cards:
		deck_manager.hand.erase(card)
		deck_manager.discard_pile.append(card)
		# Ambil kartu baru dari draw pile kalau masih ada
		if not deck_manager.draw_pile.is_empty():
			deck_manager.hand.append(deck_manager.draw_pile.pop_back())
		elif not deck_manager.discard_pile.is_empty():
			deck_manager.refill_from_discard()
			if not deck_manager.draw_pile.is_empty():
				deck_manager.hand.append(deck_manager.draw_pile.pop_back())
	
	selected_cards.clear()
	_update_ui()
	_render_hand()
	_update_buttons()

	if current_score >= target_score:
		_show_overlay_win()
		return

	if hands_played >= max_hands:
		_show_overlay_lose()
		return
func _on_discard_pressed():
	if selected_cards.is_empty():
		return
	if not jp_manager.can_discard(selected_cards.size()):
		hand_type_label.text = "✗ JP tidak cukup untuk discard"
		return
	jp_manager.spend_discard(selected_cards.size())
	deck_manager.discard_cards(selected_cards)
	selected_cards.clear()
	for i in range(min(5, deck_manager.draw_pile.size())):
		if deck_manager.hand.size() < DeckManager.HAND_SIZE:
			deck_manager.hand.append(deck_manager.draw_pile.pop_back())
	_render_hand()
	_update_buttons()


func _on_jp_changed(current: int, maximum: int):
	jp_label.text = "JP: " + str(current) + "/" + str(maximum)

func _update_ui():
	score_label.text = "Score: " + str(current_score) + " / " + str(target_score)
	target_label.text = "Hands: " + str(hands_played) + "/" + str(max_hands) + \
		"   Stage: " + str(stage)

func _update_buttons():
	btn_play.disabled = selected_cards.is_empty()
	btn_discard.disabled = selected_cards.is_empty() or jp_manager.is_empty()

func _show_overlay_win():
	btn_play.disabled = true
	btn_discard.disabled = true
	selected_cards.clear()
	# hapus semua card button
	for child in hand_container.get_children():
		child.queue_free()
	overlay_title.text = "STAGE CLEAR"
	overlay_sub.text = "Score: " + str(current_score) + " / " + str(target_score) + \
		"\nStage " + str(stage) + " selesai.\nLanjut ke stage berikutnya?"
	btn_continue.visible = true
	btn_stop.visible = true
	btn_continue.text = "Lanjut (Target: " + str(int(target_score * 1.33)) + ")"
	btn_stop.text = "Stop di sini"
	overlay.visible = true

func _show_overlay_lose():
	btn_play.disabled = true
	btn_discard.disabled = true
	selected_cards.clear()
	# hapus semua card button
	for child in hand_container.get_children():
		child.queue_free()
	overlay_title.text = "GAME OVER"
	overlay_sub.text = "Score: " + str(current_score) + " / " + str(target_score) + \
		"\nKamu tidak mencapai target dalam " + str(max_hands) + " hands."
	btn_continue.visible = false
	btn_stop.visible = true
	btn_stop.text = "Coba Lagi"
	overlay.visible = true
func _on_continue_pressed():
	stage += 1
	target_score = int(target_score * 1.33)
	current_score = 0
	hands_played = 0
	jp_manager.reset_for_duel(0)
	deck_manager.shuffle_deck()
	overlay.visible = false
	_update_ui()
	_deal_hand()

func _on_stop_pressed():
	if btn_stop.text == "Coba Lagi":
		stage = 1
		target_score = 300
		current_score = 0
		hands_played = 0
		jp_manager.reset_for_duel(0)
		deck_manager.shuffle_deck()
		overlay.visible = false
		_update_ui()
		_deal_hand()
	else:
		overlay.visible = false
		hand_type_label.text = "Kamu berhenti di Stage " + str(stage) + \
			" dengan score " + str(current_score)
