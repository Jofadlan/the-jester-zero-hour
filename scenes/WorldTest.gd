extends Node2D

@onready var label_info = $UI/VBoxContainer/LabelInfo
@onready var btn_pick_nightly = $UI/VBoxContainer/BtnPickNightly
@onready var btn_pick_oily = $UI/VBoxContainer/BtnPickOily
@onready var btn_slot1 = $UI/VBoxContainer/BtnSlot1
@onready var btn_slot2 = $UI/VBoxContainer/BtnSlot2
@onready var btn_go_combat = $UI/VBoxContainer/BtnGoCombat
@onready var btn_go_boss = $UI/VBoxContainer/BtnGoBoss


var selected_joker: JokerData = null

func _ready():
	btn_pick_nightly.pressed.connect(_on_pick_nightly)
	btn_pick_oily.pressed.connect(_on_pick_oily)
	btn_slot1.pressed.connect(_on_equip_slot1)
	btn_slot2.pressed.connect(_on_equip_slot2)
	btn_go_combat.pressed.connect(_on_go_combat)
	btn_go_boss.pressed.connect(_on_go_boss)
	_update_info()

func _on_pick_nightly():
	selected_joker = JokerFactory.create_nightly_prowess()
	_update_info()

func _on_pick_oily():
	selected_joker = JokerFactory.create_oily_torch()
	_update_info()

func _on_equip_slot1():
	if selected_joker == null:
		_show_feedback("✗ Pilih Joker dulu sebelum equip.", false)
		return
	var before = GameManager.joker_slots[0]
	selected_joker.reveal()
	GameManager.equip_joker(selected_joker, 0)
	if GameManager.joker_slots[0] == before:
		_show_feedback("✗ " + selected_joker.display_name + " sudah terpasang di slot lain.", false)
		return
	_show_feedback("✦ " + selected_joker.display_name + " dipasang ke Slot 1.", true)
	selected_joker = null
	_update_info()

func _on_equip_slot2():
	if selected_joker == null:
		_show_feedback("✗ Pilih Joker dulu sebelum equip.", false)
		return
	var before = GameManager.joker_slots[1]
	selected_joker.reveal()
	GameManager.equip_joker(selected_joker, 1)
	if GameManager.joker_slots[1] == before:
		_show_feedback("✗ " + selected_joker.display_name + " sudah terpasang di slot lain.", false)
		return
	_show_feedback("✦ " + selected_joker.display_name + " dipasang ke Slot 2.", true)
	selected_joker = null
	_update_info()

func _show_feedback(message: String, success: bool):
	label_info.text = message
	if success:
		label_info.modulate = Color(0.8, 1.0, 0.4)  # Hijau kekuningan
	else:
		label_info.modulate = Color(1.0, 0.3, 0.3)  # Merah
	
	# Reset warna setelah 2 detik
	await get_tree().create_timer(2.0).timeout
	label_info.modulate = Color.WHITE
	_update_info()


func _on_go_boss():
	GameManager.combat_mode = "boss"
	get_tree().change_scene_to_file("res://scenes/CombatScene.tscn")

# update _on_go_combat() juga:
func _on_go_combat():
	GameManager.combat_mode = "normal"
	get_tree().change_scene_to_file("res://scenes/CombatScene.tscn")

func _update_info():
	var text = "═══ JOKER SLOTS ═══\n\n"
	for i in 2:
		var joker = GameManager.joker_slots[i]
		if joker:
			var tier_icon = "▲" if joker.tier == JokerData.JokerTier.BUFF else "▼"
			text += tier_icon + " Slot " + str(i+1) + ": " + joker.display_name + "\n"
			text += "   Cost: " + str(joker.jp_cost) + " JP\n"
			text += "   " + joker.get_description() + "\n\n"
		else:
			text += "○ Slot " + str(i+1) + ": [kosong]\n\n"
	
	text += "═══ SELECTED ═══\n\n"
	if selected_joker:
		var tier_text = "BUFF" if selected_joker.tier == JokerData.JokerTier.BUFF else "DEBUFF"
		text += selected_joker.display_name + " [" + tier_text + "]\n"
		text += "Cost: " + str(selected_joker.jp_cost) + " JP\n"
		text += selected_joker.get_description()
	else:
		text += "Belum ada Joker dipilih."
	
	label_info.text = text
	label_info.modulate = Color.WHITE
