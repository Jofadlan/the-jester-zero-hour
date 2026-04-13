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
@onready var narrative_panel = $UI/NarrativePanel
@onready var narrative_text = $UI/NarrativePanel/VBoxContainer/NarrativeText
@onready var btn_choice1 = $UI/NarrativePanel/VBoxContainer/BtnChoice1
@onready var btn_choice2 = $UI/NarrativePanel/VBoxContainer/BtnChoice2

var evaluator: HandEvaluator
var selected_cards: Array[Card] = []
var current_score: int = 0
var target_score: int = 300
var hands_played: int = 0
var max_hands: int = 4
var stage: int = 1

#joker
var nightly_prowess_active: bool = false
var oily_torch_used: bool = false
var oily_torch_pending: bool = false
var invisible_semut_active: bool = false
var hidden_sinew_active: bool = false
var late_arrival_active: bool = false

#boss 
var is_boss_fight: bool = false
var boss_data: BossData = null
var current_boss_stage: int = 0
var current_stage_effect: String = ""
var narrative_phases: Array = []
var current_narrative: NarrativePhase = null


const HAND_NAMES = {
	0: "High Card", 1: "Pair", 2: "Two Pair",
	3: "Three of a Kind", 4: "Straight", 5: "Flush",
	6: "Full House", 7: "Four of a Kind",
	8: "Straight Flush", 9: "Royal Flush"}

func _ready():
	evaluator = HandEvaluator.new()
	jp_manager.jp_changed.connect(_on_jp_changed)
	
	btn_play.pressed.connect(_on_play_pressed)
	btn_discard.pressed.connect(_on_discard_pressed)
	btn_joker1.pressed.connect(_on_joker_slot_pressed.bind(0))
	btn_joker2.pressed.connect(_on_joker_slot_pressed.bind(1))
	btn_continue.pressed.connect(_on_continue_pressed)
	btn_stop.pressed.connect(_on_stop_pressed)
	
	btn_play.disabled = true
	btn_discard.disabled = true
	overlay.visible = false
	
	btn_choice1.pressed.connect(_on_choice_pressed.bind(0))
	btn_choice2.pressed.connect(_on_choice_pressed.bind(1))
	narrative_panel.visible = false
	
	# Setup combat berdasarkan mode
	if GameManager.combat_mode == "boss":
		var boss = BossData.new("THE LOVERS", [
			BossData.StageData.new(300),
			BossData.StageData.new(500, "discard_random_2")
		])
		setup_boss_combat(boss)
	else:
		setup_normal_combat()
		jp_manager.reset_for_duel(GameManager.get_joker_count())
	
	_update_ui()
	_update_joker_display()
	_deal_hand()
	# ── CORRUPTION TINT REGISTRATION ──
	# Accent nodes: warna utama yang berubah gold → deep red
	UICorruptionTint.register(score_label,     "theme_override_colors/font_color")
	UICorruptionTint.register(jp_label,        "theme_override_colors/font_color")
	UICorruptionTint.register(slot1_name,      "theme_override_colors/font_color")
	UICorruptionTint.register(slot2_name,      "theme_override_colors/font_color")
 
	# Muted nodes: warna sekunder (lebih gelap, berubah lebih subtil)
	UICorruptionTint.register(hand_type_label, "theme_override_colors/font_color", true)
	UICorruptionTint.register(target_label,    "theme_override_colors/font_color", true)
 
	# Force sync agar warna langsung sesuai corruption saat scene dibuka
	UICorruptionTint.force_sync()

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
	
	if nightly_prowess_active:
		var upgraded_type = min(eval_result["hand_type"] + 1, 9)
		var upgraded_base = HandEvaluator.HAND_DATA[upgraded_type]
		var card_chips = eval_result["chips"] - HandEvaluator.HAND_DATA[eval_result["hand_type"]]["chips"]
		score = (upgraded_base["chips"] + card_chips) * upgraded_base["mult"]
		nightly_prowess_active = false
		hand_type_label.text = "✦ Upgraded! +" + str(score) + " pts"
	
	if hidden_sinew_active:
		var low_card_bonus = 0
		for card in selected_cards:
			if card.rank <= Card.Rank.FIVE:
				low_card_bonus += 15
		score += low_card_bonus
		hidden_sinew_active = false

	if late_arrival_active:
	# Skip hand ini — tidak mengurangi hands_played
		late_arrival_active = false
		hand_type_label.text = "✦ Late Arrival — hand ini tidak dihitung."
		for card in selected_cards:
			deck_manager.hand.erase(card)
			deck_manager.discard_pile.append(card)
			if not deck_manager.draw_pile.is_empty():
				deck_manager.hand.append(deck_manager.draw_pile.pop_back())
		selected_cards.clear()
		_render_hand()
		_update_buttons()
		_update_joker_display()
		return  # Early return — tidak tambah hands_played
	
	if oily_torch_used:
		score *= 2
		oily_torch_pending = true
		oily_torch_used = false
	
	current_score += score
	hands_played += 1
	
	if not nightly_prowess_active:
		hand_type_label.text = HAND_NAMES.get(eval_result["hand_type"], "?") + \
			"  +  " + str(score) + " pts"
	
	# Ganti kartu yang dimainkan
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
	
	# Efek boss stage — discard 2 kartu random
	if current_stage_effect == "discard_random_2":
		_apply_discard_random(2)
	
	_update_ui()
	_render_hand()
	_update_buttons()
	_update_joker_display()
	
	# Cek apakah ada narrative phase yang harus ditrigger
	if is_boss_fight:
		_check_narrative_trigger()

	if current_score >= target_score:
		_check_win()
		return

	if hands_played >= max_hands:
		_show_overlay_lose()
		return

func _apply_discard_random(amount: int):
	var available = deck_manager.hand.duplicate()
	available.shuffle()
	var to_discard = available.slice(0, min(amount, available.size()))
	for card in to_discard:
		deck_manager.hand.erase(card)
		deck_manager.discard_pile.append(card)
		# Langsung ganti dengan kartu baru dari draw pile
		if not deck_manager.draw_pile.is_empty():
			deck_manager.hand.append(deck_manager.draw_pile.pop_back())
		elif not deck_manager.discard_pile.is_empty():
			deck_manager.refill_from_discard()
			if not deck_manager.draw_pile.is_empty():
				deck_manager.hand.append(deck_manager.draw_pile.pop_back())
	hand_type_label.text += "\n⚠ " + str(to_discard.size()) + " kartu dibuang paksa!"

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
	overlay_title.text = "VICTORY"
	overlay_sub.text = "Score: " + str(current_score) + " / " + str(target_score)
	btn_continue.visible = false
	btn_stop.visible = true
	btn_stop.text = "Selesai"
	overlay.visible = true
	UICorruptionTint.register(overlay_title, "theme_override_colors/font_color")
	UICorruptionTint.register(overlay_sub,   "theme_override_colors/font_color", true)
 
func _show_overlay_lose():
	btn_play.disabled = true
	btn_discard.disabled = true
	btn_joker1.disabled = true
	btn_joker2.disabled = true
	selected_cards.clear()
	for child in hand_container.get_children():
		child.queue_free()
	
	# Corruption naik kalau kalah boss
	if is_boss_fight:
		GameManager.add_corruption(15)
		print("[Corruption] Kalah boss +15 → total: ", GameManager.corruption)
	
	overlay_title.text = "GAME OVER"
	overlay_sub.text = "Score: " + str(current_score) + " / " + str(target_score) + \
		"\nKamu tidak mencapai target dalam " + str(max_hands) + " hands."
	btn_continue.visible = false
	btn_stop.visible = true
	btn_stop.text = "Coba Lagi"
	overlay.visible = true
	UICorruptionTint.register(overlay_title, "theme_override_colors/font_color")
	UICorruptionTint.register(overlay_sub,   "theme_override_colors/font_color", true)
 
func _on_continue_pressed():
	if is_boss_fight:
		if oily_torch_pending:
			boss_data.stages[current_boss_stage].target_score = \
				int(boss_data.stages[current_boss_stage].target_score * 2)
			oily_torch_pending = false
			
		_apply_boss_stage(current_boss_stage)
		deck_manager.shuffle_deck()
		overlay.visible = false
		btn_discard.disabled = false
		btn_joker1.disabled = false
		btn_joker2.disabled = false
		_update_ui()
		_update_joker_display()
		_deal_hand()
	else:
		stage += 1
		target_score = int(target_score * 1.33)
		if oily_torch_pending:
			target_score = int(target_score * 2)
			oily_torch_pending = false
		current_score = 0
		hands_played = 0
		nightly_prowess_active = false
		jp_manager.reset_for_duel(GameManager.get_joker_count())
		deck_manager.shuffle_deck()
		overlay.visible = false
		btn_discard.disabled = false
		btn_joker1.disabled = false
		btn_joker2.disabled = false
		_update_ui()
		_update_joker_display()
		_deal_hand()

func _on_stop_pressed():
	if is_boss_fight:
		# Kalah boss atau selesai → balik ke world
		GameManager.combat_mode = "normal"
	else:
		if btn_stop.text == "Coba Lagi":
			stage = 1
			target_score = 300
			current_score = 0
			hands_played = 0
			nightly_prowess_active = false
			oily_torch_pending = false
			jp_manager.reset_for_duel(GameManager.get_joker_count())
			deck_manager.shuffle_deck()
			overlay.visible = false
			btn_discard.disabled = false
			btn_joker1.disabled = false
			btn_joker2.disabled = false
			_update_ui()
			_update_joker_display()
			_deal_hand()
		else:
			overlay.visible = false
			hand_type_label.text = "Kamu berhenti di Stage " + str(stage) + \
				" dengan score " + str(current_score)
	get_tree().change_scene_to_file("res://scenes/WorldTest.tscn")

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
		
		JokerData.JokerType.THE_INVISIBLE_SEMUT:
			invisible_semut_active = true
			hand_type_label.text = "✦ The Invisible Semut aktif!"
		
		JokerData.JokerType.HIDDEN_SINEW:
			hidden_sinew_active = true
			hand_type_label.text = "✦ Hidden Sinew aktif!"
		
		JokerData.JokerType.TACTICIANS_SATIRE:
			_reveal_next_stage_target()
			hand_type_label.text = "✦ Tactician's Satire — target stage berikutnya terungkap."
		
		JokerData.JokerType.THE_LATE_ARRIVAL:
			late_arrival_active = true
			hand_type_label.text = "✦ The Late Arrival aktif — skip hand berikutnya aman."
		
		JokerData.JokerType.SHADOW_MENTOR:
			_show_top_deck_preview()
			hand_type_label.text = "✦ Shadow Mentor — 3 kartu teratas deck terungkap."
		
		JokerData.JokerType.VAIN_PRESERVATION:
			GameManager.add_corruption(8)
			hand_type_label.text = "✦ Vain Preservation aktif."
			# Tidak ada feedback corruption — diam-diam
		
		JokerData.JokerType.NONE:
			hand_type_label.text = "..."
			# Tidak ada efek. Sengaja.
	
	return true

func _on_joker_slot_pressed(slot_index: int):
	if activate_joker(slot_index):
		_update_joker_display()

func setup_normal_combat():
	is_boss_fight = false
	target_score = 300
	max_hands = 4
	current_stage_effect = ""

func setup_boss_combat(boss: BossData):
	is_boss_fight = true
	boss_data = boss
	current_boss_stage = 0
	_apply_boss_stage(0)
	# Setup narrative phase untuk boss ini
	narrative_phases = [
		NarrativePhase.new(1, 2,
			"Di tengah duel, musuhmu berhenti sejenak.\n\"Kau bisa menyerah sekarang. Tidak ada yang perlu terluka lebih jauh.\"\n\nApa yang kamu lakukan?",
			[
				NarrativePhase.Choice.new("\"Aku tidak akan menyerah.\" — Lanjutkan pertarungan.", -5),
				NarrativePhase.Choice.new("Ragu sejenak. Mungkin ia benar... — Tapi tetap lanjut.", 10)
			]
		)
	]

func _apply_boss_stage(stage_index: int):
	var stage = boss_data.stages[stage_index]
	target_score = stage.target_score
	current_stage_effect = stage.effect
	max_hands = 4
	current_score = 0
	hands_played = 0
	jp_manager.reset_for_duel(GameManager.get_joker_count())
	
	# Update label stage
	hand_type_label.text = "[ " + boss_data.display_name + \
		" — Stage " + str(stage_index + 1) + "/" + \
		str(boss_data.stages.size()) + " ]"
	
	if current_stage_effect == "discard_random_2":
		hand_type_label.text += "\n⚠ Efek: 2 kartu random dibuang tiap play hand"

func _check_win():
	if is_boss_fight:
		var next_stage = current_boss_stage + 1
		if next_stage < boss_data.stages.size():
			# Lanjut ke stage boss berikutnya
			current_boss_stage = next_stage
			_show_overlay_boss_next()
		else:
			# Boss defeated
			_show_overlay_boss_defeated()
	else:
		_show_overlay_win()

func _show_overlay_boss_next():
	btn_play.disabled = true
	btn_discard.disabled = true
	btn_joker1.disabled = true
	btn_joker2.disabled = true
	selected_cards.clear()
	for child in hand_container.get_children():
		child.queue_free()
	overlay_title.text = "STAGE " + str(current_boss_stage) + " CLEAR"
	overlay_sub.text = "Bersiap untuk stage berikutnya...\n" + \
		"Target: " + str(boss_data.stages[current_boss_stage].target_score)
	btn_continue.visible = true
	btn_stop.visible = false
	btn_continue.text = "Lanjutkan"
	overlay.visible = true

func _show_overlay_boss_defeated():
	btn_play.disabled = true
	btn_discard.disabled = true
	btn_joker1.disabled = true
	btn_joker2.disabled = true
	selected_cards.clear()
	for child in hand_container.get_children():
		child.queue_free()
	overlay_title.text = "✦ BOSS DEFEATED"
	overlay_sub.text = boss_data.display_name + " telah dikalahkan!"
	btn_continue.visible = false
	btn_stop.visible = true
	btn_stop.text = "Selesai"
	overlay.visible = true

func _check_narrative_trigger():
	for phase in narrative_phases:
		if phase.already_triggered:
			continue
		if phase.trigger_at_stage == current_boss_stage and \
		   phase.trigger_at_hands <= hands_played:
			_trigger_narrative(phase)
			return

func _trigger_narrative(phase: NarrativePhase):
	phase.already_triggered = true
	current_narrative = phase
	
	# Pause combat
	btn_play.disabled = true
	btn_discard.disabled = true
	btn_joker1.disabled = true
	btn_joker2.disabled = true
	
	narrative_text.text = phase.narrative_text
	btn_choice1.text = phase.choices[0].text
	btn_choice2.text = phase.choices[1].text
	narrative_panel.visible = true
	
	# Tint teks naratif
	UICorruptionTint.register(narrative_text, "theme_override_colors/font_color", true)
 
	narrative_text.text  = phase.narrative_text
	btn_choice1.text     = phase.choices[0].text
	btn_choice2.text     = phase.choices[1].text
	narrative_panel.visible = true

func _on_choice_pressed(choice_index: int):
	if current_narrative == null:
		return
	
	var choice = current_narrative.choices[choice_index]
	GameManager.add_corruption(choice.corruption_delta)
	print("[Corruption] Pilihan narrative: ", choice.corruption_delta, \
		" → total: ", GameManager.corruption, \
		" (tier: ", GameManager.get_corruption_tier(), ")")
	
	current_narrative = null
	narrative_panel.visible = false
	
	# Resume combat
	btn_play.disabled = selected_cards.is_empty()
	btn_discard.disabled = selected_cards.is_empty() or jp_manager.is_empty()
	_update_joker_display()
	
	# Cek win/lose yang tertunda
	if current_score >= target_score:
		_check_win()
	elif hands_played >= max_hands:
		_show_overlay_lose()

func _reveal_next_stage_target() -> void:
	var next_target: int
	if is_boss_fight:
		var next_stage_idx = current_boss_stage + 1
		if next_stage_idx < boss_data.stages.size():
			next_target = boss_data.stages[next_stage_idx].target_score
			hand_type_label.text = "Stage berikutnya: target " + str(next_target)
		else:
			hand_type_label.text = "Ini stage terakhir."
	else:
		next_target = int(target_score * 1.33)
		if oily_torch_pending:
			next_target = int(next_target * 2)
		hand_type_label.text = "Stage berikutnya: target ~" + str(next_target)

func _show_top_deck_preview() -> void:
	var preview = deck_manager.draw_pile.slice(
		max(0, deck_manager.draw_pile.size() - 3),
		deck_manager.draw_pile.size()
	)
	var names = preview.map(func(c): return c.get_display_name())
	names.reverse()  # top of deck duluan
	hand_type_label.text = "Deck: " + ", ".join(names) + "..."
