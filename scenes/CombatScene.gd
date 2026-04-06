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
@onready var slot1_name = $UI/JokerPanel/Slot1Container/Slot1Name
@onready var slot2_name = $UI/JokerPanel/Slot2Container/Slot2Name
@onready var btn_slot1 = $UI/JokerPanel/Slot1Container/BtnSlot1
@onready var btn_slot2 = $UI/JokerPanel/Slot2Container/BtnSlot2
@onready var btn_joker1 = $UI/JokerPanel/Slot1Container/BtnSlot1
@onready var btn_joker2 = $UI/JokerPanel/Slot2Container/BtnSlot2

var evaluator: HandEvaluator
var selected_cards: Array[Card] = []
var current_score: int = 0
var target_score: int = 300
var hands_played: int = 0
var max_hands: int = 4
var stage: int = 1
var nightly_prowess_active: bool = false
var oily_torch_used: bool = false

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
	
	jp_manager.reset_for_duel(GameManager.get_joker_count())
	_update_joker_display()

	btn_play.pressed.connect(_on_play_pressed)
	btn_discard.pressed.connect(_on_discard_pressed)
	btn_continue.pressed.connect(_on_continue_pressed)
	btn_stop.pressed.connect(_on_stop_pressed)

	btn_play.disabled = true
	btn_discard.disabled = true
	overlay.visible = false
	
	btn_slot1.pressed.connect(_on_joker_slot_pressed.bind(0))
	btn_slot2.pressed.connect(_on_joker_slot_pressed.bind(1))

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
	
	var eval_result = evaluator.evaluate(selected_cards)
	var score = eval_result["score"]
	
	# Nightly Prowess — upgrade hand type satu tier
	if nightly_prowess_active:
		var upgraded_type = min(eval_result["hand_type"] + 1, 9)
		var upgraded_base = HandEvaluator.HAND_DATA[upgraded_type]
		var card_chips = eval_result["chips"] - HandEvaluator.HAND_DATA[eval_result["hand_type"]]["chips"]
		score = (upgraded_base["chips"] + card_chips) * upgraded_base["mult"]
		nightly_prowess_active = false
		hand_type_label.text = "✦ Upgraded! +" + str(score) + " pts"
	
	# Oily Torch — score x2
	if oily_torch_used:
		score *= 2
		oily_torch_used = false
	
	current_score += score
	hands_played += 1
	
	if not nightly_prowess_active:
		hand_type_label.text = HAND_NAMES.get(eval_result["hand_type"], "?") + \
			"  +  " + str(score) + " pts"
	
	for card in selected_cards:
		deck_manager.hand.erase(card)
		deck_manager.discard_pile.append(card)
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
	btn_joker1.disabled = true
	btn_joker2.disabled = true
	selected_cards.clear()
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
	btn_joker1.disabled = true
	btn_joker2.disabled = true
	selected_cards.clear()
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
	if oily_torch_used:
		target_score = int(target_score * 2)
		oily_torch_used = false
	current_score = 0
	hands_played = 0
	nightly_prowess_active = false
	
	# Reset JP dengan perhitungkan jumlah Joker
	jp_manager.reset_for_duel(GameManager.get_joker_count())
	
	deck_manager.shuffle_deck()
	overlay.visible = false
	
	# Re-enable semua tombol
	btn_discard.disabled = false
	btn_joker1.disabled = false
	btn_joker2.disabled = false
	
	_update_ui()
	_update_joker_display()
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

func _update_joker_display():
	for i in 2:
		var joker = GameManager.joker_slots[i]
		var name_label = slot1_name if i == 0 else slot2_name
		var btn = btn_slot1 if i == 0 else btn_slot2
		
		if joker:
			name_label.text = joker.display_name + "\n" + \
				joker.get_description() + "\n(Cost: " + str(joker.jp_cost) + " JP)"
			btn.disabled = not jp_manager.can_use_joker(joker.jp_cost)
			btn.text = "Aktifkan"
		else:
			name_label.text = "[kosong]"
			btn.disabled = true
			btn.text = "—"
func activate_joker(slot_index: int) -> bool:
	var joker = GameManager.joker_slots[slot_index]
	if joker == null:
		return false
	if not jp_manager.can_use_joker(joker.jp_cost):
		hand_type_label.text = "✗ JP tidak cukup"
		return false
	
	jp_manager.spend_joker(joker.jp_cost)
	
	match joker.joker_type:
		JokerData.JokerType.NIGHTLY_PROWESS:
			nightly_prowess_active = true
			hand_type_label.text = "✦ Nightly Prowess aktif!"
		JokerData.JokerType.THE_OILY_TORCH:
			oily_torch_used = true
			hand_type_label.text = "✦ The Oily Torch aktif!"
	
	return true
func _on_joker_slot_pressed(slot_index: int):
	if activate_joker(slot_index):
		_update_joker_display()
