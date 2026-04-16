extends Node2D

@onready var label_location : Label   = $UI/LabelLocation
@onready var dialogue_box   : Control = $UI/DialogueBox
@onready var label_speaker  : Label   = $UI/DialogueBox/VBox/LabelSpeaker
@onready var label_text     : Label   = $UI/DialogueBox/VBox/LabelText
@onready var btn_next       : Button  = $UI/DialogueBox/VBox/HBox/BtnNext
@onready var btn_close      : Button  = $UI/DialogueBox/VBox/HBox/BtnClose

@onready var btn_magician   : Button  = $UI/NPCButtons/BtnMagician
@onready var btn_emperor    : Button  = $UI/NPCButtons/BtnEmperor
@onready var btn_priestess  : Button  = $UI/NPCButtons/BtnPriestess
@onready var btn_go_combat  : Button  = $UI/NPCButtons/BtnGoCombat
@onready var btn_go_boss    : Button  = $UI/NPCButtons/BtnGoBoss
@onready var btn_joker_menu : Button  = $UI/NPCButtons/BtnJokerMenu

@onready var joker_panel    : Control = $UI/JokerPanel
@onready var label_slots    : Label   = $UI/JokerPanel/VBox/LabelSlots
@onready var btn_pick_j1    : Button  = $UI/JokerPanel/VBox/HBoxPick/BtnPickJ1
@onready var btn_pick_j2    : Button  = $UI/JokerPanel/VBox/HBoxPick/BtnPickJ2
@onready var btn_equip1     : Button  = $UI/JokerPanel/VBox/HBoxEquip/BtnEquip1
@onready var btn_equip2     : Button  = $UI/JokerPanel/VBox/HBoxEquip/BtnEquip2
@onready var btn_unequip1   : Button  = $UI/JokerPanel/VBox/HBoxUnequip/BtnUnequip1
@onready var btn_unequip2   : Button  = $UI/JokerPanel/VBox/HBoxUnequip/BtnUnequip2
@onready var btn_close_joker: Button  = $UI/DialogueBox/VBox/HBox/BtnClose

var _dialogue_queue  : Array[String] = []
var _current_speaker : String        = ""
var _selected_joker  : JokerData     = null

const TEST_JOKERS = [
	JokerData.JokerType.NIGHTLY_PROWESS,
	JokerData.JokerType.THE_OILY_TORCH,
	JokerData.JokerType.SHADOW_MENTOR,
	JokerData.JokerType.THE_INVISIBLE_SEMUT,
	JokerData.JokerType.HIDDEN_SINEW,
	JokerData.JokerType.TACTICIANS_SATIRE,
	JokerData.JokerType.THE_LATE_ARRIVAL,
	JokerData.JokerType.VAIN_PRESERVATION,
	JokerData.JokerType.NONE,
]
var _joker_page : int = 0

func _ready():
	dialogue_box.hide()
	joker_panel.hide()
	label_location.text = "Aula Kerajaan"

	btn_magician.pressed.connect(_talk_magician)
	btn_emperor.pressed.connect(_talk_emperor)
	btn_priestess.pressed.connect(_talk_priestess)
	btn_go_combat.pressed.connect(_on_go_combat)
	btn_go_boss.pressed.connect(_on_go_boss)
	btn_joker_menu.pressed.connect(_open_joker_panel)
	btn_next.pressed.connect(_advance_dialogue)
	btn_close.pressed.connect(_close_dialogue)
	btn_pick_j1.pressed.connect(_joker_prev)
	btn_pick_j2.pressed.connect(_joker_next)
	btn_equip1.pressed.connect(_equip.bind(0))
	btn_equip2.pressed.connect(_equip.bind(1))
	btn_unequip1.pressed.connect(_unequip.bind(0))
	btn_unequip2.pressed.connect(_unequip.bind(1))
	btn_close_joker.pressed.connect(func(): joker_panel.hide())

	_apply_npc_mood()

# ── NAVIGATION ────────────────────────────────────

func _on_go_combat():
	GameManager.combat_mode = "normal"
	get_tree().change_scene_to_file("res://scenes/CombatScene.tscn")

func _on_go_boss():
	GameManager.combat_mode = "boss"
	get_tree().change_scene_to_file("res://scenes/CombatScene.tscn")

# ── JOKER PANEL ───────────────────────────────────

func _open_joker_panel():
	_joker_page = 0
	_selected_joker = JokerFactory.create_by_type(TEST_JOKERS[_joker_page])
	joker_panel.show()
	dialogue_box.hide()
	_update_joker_panel()

func _joker_prev():
	_joker_page = (_joker_page - 1 + TEST_JOKERS.size()) % TEST_JOKERS.size()
	_selected_joker = JokerFactory.create_by_type(TEST_JOKERS[_joker_page])
	_update_joker_panel()

func _joker_next():
	_joker_page = (_joker_page + 1) % TEST_JOKERS.size()
	_selected_joker = JokerFactory.create_by_type(TEST_JOKERS[_joker_page])
	_update_joker_panel()

func _equip(slot: int):
	if _selected_joker == null:
		return
	var clone = JokerFactory.create_by_type(_selected_joker.joker_type)
	clone.reveal()
	var before = GameManager.joker_slots[slot]
	GameManager.equip_joker(clone, slot)
	if GameManager.joker_slots[slot] == before:
		return
	_update_joker_panel()

func _unequip(slot: int):
	GameManager.unequip_joker(slot)
	_update_joker_panel()

func _update_joker_panel():
	var j = _selected_joker
	var tier_label = {
		JokerData.JokerTier.BUFF: "BUFF",
		JokerData.JokerTier.DEBUFF: "DEBUFF",
		JokerData.JokerTier.NEUTRAL: "NEUTRAL",
	}
	var text = "[ %d / %d ]  %s  [%s · %d JP]\n%s\n\n" % [
		_joker_page + 1, TEST_JOKERS.size(),
		j.display_name, tier_label[j.tier], j.jp_cost, j.description
	]
	text += "JP max preview: %d\n\n" % (10 + GameManager.get_joker_count() * 4)
	for i in 2:
		var slot = GameManager.joker_slots[i]
		text += "Slot %d: %s\n" % [i + 1, slot.display_name if slot else "[kosong]"]
	label_slots.text = text

# ── NPC DIALOGUE ──────────────────────────────────

func _talk_magician():
	var tier = GameManager.get_corruption_tier()
	match tier:
		"jester":
			_open_dialogue("The Magician", [
				"Ah, si pelawak malam. Kau berlatih lagi tadi malam, bukan?",
				"Tanganmu... tidak seperti tangan badut biasa.",
				"Jika kau butuh buku taktik — perpustakaanku terbuka.",
			])
		"grey":
			_open_dialogue("The Magician", [
				"Matamu semakin berat hari ini.",
				"Aku pernah melihat mata seperti itu. Orang yang menanggung sesuatu terlalu lama.",
				"Hati-hati. Beban itu bisa mengubah caramu memegang pedang.",
			])
		"joker":
			_open_dialogue("The Magician", [
				"...",
				"Kau masih di sini. Aku kira kau sudah pergi.",
				"Tidak ada yang ingin bicara denganmu lagi. Kau tahu itu, bukan?",
			])

func _talk_emperor():
	var tier = GameManager.get_corruption_tier()
	match tier:
		"jester":
			_open_dialogue("The Emperor", [
				"Badut! Sudah siang. Kau seharusnya menghibur, bukan melamun.",
				"Aku tidak membayarmu untuk berpikir.",
				"Pergilah. Kembali saat kau punya lelucon yang layak.",
			])
		"grey":
			_open_dialogue("The Emperor", [
				"Kau tampak aneh belakangan ini.",
				"Para penasihat bilang kau sering terlihat di perpustakaan malam hari.",
				"Badut yang membaca buku taktik perang. Lucu sekali.",
			])
		"joker":
			_open_dialogue("The Emperor", [
				"Aku tidak mau melihatmu hari ini.",
				"Pergi.",
			])

func _talk_priestess():
	var tier = GameManager.get_corruption_tier()
	match tier:
		"jester":
			_open_dialogue("The High Priestess", [
				"...",
				"*Ia menatapmu dengan ekspresi yang sulit dibaca.*",
				"*Matanya tidak bergerak dari wajahmu, seolah ia melihat sesuatu di baliknya.*",
				"*Ia tidak berkata apa-apa. Tapi raut wajahnya — iba.*",
			])
		"grey":
			_open_dialogue("The High Priestess", [
				"...",
				"*Ia mengulurkan tangan sejenak, lalu menariknya kembali.*",
				"*Bibirnya bergerak, tapi tidak ada suara.*",
			])
		"joker":
			_open_dialogue("The High Priestess", [
				"*Ia berpaling darimu.*",
				"*Pertama kalinya.*",
			])

# ── DIALOGUE ENGINE ───────────────────────────────

func _open_dialogue(speaker: String, lines: Array[String]):
	_current_speaker = speaker
	_dialogue_queue  = lines.duplicate()
	joker_panel.hide()
	dialogue_box.show()
	_advance_dialogue()

func _advance_dialogue():
	if _dialogue_queue.is_empty():
		_close_dialogue(); return
	label_speaker.text = _current_speaker
	label_text.text    = _dialogue_queue.pop_front()

func _close_dialogue():
	dialogue_box.hide()
	_dialogue_queue.clear()

func _apply_npc_mood():
	var tier = GameManager.get_corruption_tier()
	match tier:
		"grey":
			btn_magician.modulate  = Color(0.85, 0.82, 0.78)
			btn_emperor.modulate   = Color(0.85, 0.82, 0.78)
			btn_priestess.modulate = Color(0.85, 0.82, 0.78)
		"joker":
			btn_magician.modulate  = Color(0.70, 0.60, 0.60)
			btn_emperor.modulate   = Color(0.70, 0.60, 0.60)
			btn_priestess.modulate = Color(0.55, 0.50, 0.50)
