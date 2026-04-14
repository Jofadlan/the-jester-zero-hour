extends Node2D

@onready var label_info             = $UI/ScrollContainer/VBoxContainer/LabelInfo
@onready var btn_pick_invisible     = $UI/ScrollContainer/VBoxContainer/BtnPickInvisibleSemut
@onready var btn_pick_sinew         = $UI/ScrollContainer/VBoxContainer/BtnPickHiddenSinew
@onready var btn_pick_satire        = $UI/ScrollContainer/VBoxContainer/BtnPickTacticiansSatire
@onready var btn_pick_late          = $UI/ScrollContainer/VBoxContainer/BtnPickLateArrival
@onready var btn_pick_nightly       = $UI/ScrollContainer/VBoxContainer/BtnPickNightly
@onready var btn_pick_shadow        = $UI/ScrollContainer/VBoxContainer/BtnPickShadowMentor
@onready var btn_pick_oily          = $UI/ScrollContainer/VBoxContainer/BtnPickOily
@onready var btn_pick_vain          = $UI/ScrollContainer/VBoxContainer/BtnPickVainPreservation
@onready var btn_pick_none          = $UI/ScrollContainer/VBoxContainer/BtnPickNone
@onready var btn_slot1              = $UI/ScrollContainer/VBoxContainer/BtnSlot1
@onready var btn_slot2              = $UI/ScrollContainer/VBoxContainer/BtnSlot2
@onready var btn_unequip1           = $UI/ScrollContainer/VBoxContainer/BtnUnequipSlot1
@onready var btn_unequip2           = $UI/ScrollContainer/VBoxContainer/BtnUnequipSlot2
@onready var btn_go_combat          = $UI/ScrollContainer/VBoxContainer/BtnGoCombat
@onready var btn_go_boss            = $UI/ScrollContainer/VBoxContainer/BtnGoBoss

var selected_joker: JokerData = null

func _ready():
	btn_pick_invisible.pressed.connect(_pick.bind(JokerData.JokerType.THE_INVISIBLE_SEMUT))
	btn_pick_sinew.pressed.connect(_pick.bind(JokerData.JokerType.HIDDEN_SINEW))
	btn_pick_satire.pressed.connect(_pick.bind(JokerData.JokerType.TACTICIANS_SATIRE))
	btn_pick_late.pressed.connect(_pick.bind(JokerData.JokerType.THE_LATE_ARRIVAL))
	btn_pick_nightly.pressed.connect(_pick.bind(JokerData.JokerType.NIGHTLY_PROWESS))
	btn_pick_shadow.pressed.connect(_pick.bind(JokerData.JokerType.SHADOW_MENTOR))
	btn_pick_oily.pressed.connect(_pick.bind(JokerData.JokerType.THE_OILY_TORCH))
	btn_pick_vain.pressed.connect(_pick.bind(JokerData.JokerType.VAIN_PRESERVATION))
	btn_pick_none.pressed.connect(_pick.bind(JokerData.JokerType.NONE))

	btn_slot1.pressed.connect(_on_equip_slot.bind(0))
	btn_slot2.pressed.connect(_on_equip_slot.bind(1))
	btn_unequip1.pressed.connect(_on_unequip_slot.bind(0))
	btn_unequip2.pressed.connect(_on_unequip_slot.bind(1))
	btn_go_combat.pressed.connect(_on_go_combat)
	btn_go_boss.pressed.connect(_on_go_boss)

	_update_info()

# ── PICK ──────────────────────────────────────────

func _pick(type: JokerData.JokerType):
	selected_joker = JokerFactory.create_by_type(type)
	_show_feedback("Dipilih: " + selected_joker.display_name, true)

# ── EQUIP ─────────────────────────────────────────

func _on_equip_slot(slot: int):
	if selected_joker == null:
		_show_feedback("✗ Pilih Joker dulu.", false)
		return
	var before = GameManager.joker_slots[slot]
	selected_joker.reveal()
	GameManager.equip_joker(selected_joker, slot)
	if GameManager.joker_slots[slot] == before:
		_show_feedback("✗ " + selected_joker.display_name + " sudah terpasang di slot lain.", false)
		return
	_show_feedback("✦ " + selected_joker.display_name + " → Slot " + str(slot + 1), true)
	selected_joker = null
	_update_info()

# ── UNEQUIP ───────────────────────────────────────

func _on_unequip_slot(slot: int):
	var joker = GameManager.joker_slots[slot]
	if joker == null:
		_show_feedback("✗ Slot " + str(slot + 1) + " kosong.", false)
		return
	var name = joker.display_name
	GameManager.unequip_joker(slot)
	_show_feedback("✦ " + name + " dibuang dari Slot " + str(slot + 1) + " (permanen).", true)
	_update_info()

# ── NAVIGATION ────────────────────────────────────

func _on_go_combat():
	GameManager.combat_mode = "normal"
	get_tree().change_scene_to_file("res://scenes/CombatScene.tscn")

func _on_go_boss():
	GameManager.combat_mode = "boss"
	get_tree().change_scene_to_file("res://scenes/CombatScene.tscn")

# ── UI ────────────────────────────────────────────

func _show_feedback(message: String, success: bool):
	label_info.text = message
	label_info.modulate = Color(0.8, 1.0, 0.4) if success else Color(1.0, 0.3, 0.3)
	await get_tree().create_timer(2.0).timeout
	label_info.modulate = Color.WHITE
	_update_info()

func _update_info():
	var text = "═══ JOKER SLOTS ═══\n"
	for i in 2:
		var joker = GameManager.joker_slots[i]
		if joker:
			var icon = "▲" if joker.tier == JokerData.JokerTier.BUFF \
				else ("▼" if joker.tier == JokerData.JokerTier.DEBUFF else "○")
			text += icon + " Slot " + str(i+1) + ": " + joker.display_name
			text += "  [" + str(joker.jp_cost) + " JP]\n"
			text += "   " + joker.get_description() + "\n"
		else:
			text += "○ Slot " + str(i+1) + ": [kosong]\n"

	text += "\n═══ SELECTED ═══\n"
	if selected_joker:
		var tier_map = {
			JokerData.JokerTier.BUFF: "BUFF",
			JokerData.JokerTier.DEBUFF: "DEBUFF",
			JokerData.JokerTier.NEUTRAL: "NEUTRAL"
		}
		text += selected_joker.display_name
		text += "  [" + tier_map[selected_joker.tier] + " · " + str(selected_joker.jp_cost) + " JP]\n"
		text += selected_joker.description
	else:
		text += "Belum ada Joker dipilih."

	text += "\n\nJP max (preview): " + str(10 + GameManager.get_joker_count() * 4)

	label_info.text = text
	label_info.modulate = Color.WHITE
