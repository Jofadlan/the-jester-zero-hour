extends Node2D

## Aula Kerajaan — Hub utama Act 2
## NPC yang hadir: The Magician (I), The Emperor (IV), The High Priestess (II)
## Corruption mempengaruhi reaksi NPC secara diam-diam

@onready var label_location : Label       = $UI/LabelLocation
@onready var dialogue_box   : Control     = $UI/DialogueBox
@onready var label_speaker  : Label       = $UI/DialogueBox/VBox/LabelSpeaker
@onready var label_text     : Label       = $UI/DialogueBox/VBox/LabelText
@onready var btn_next       : Button      = $UI/DialogueBox/VBox/HBox/BtnNext
@onready var btn_close      : Button      = $UI/DialogueBox/VBox/HBox/BtnClose

# NPC interact buttons
@onready var btn_magician       : Button  = $UI/NPCButtons/BtnMagician
@onready var btn_emperor        : Button  = $UI/NPCButtons/BtnEmperor
@onready var btn_priestess      : Button  = $UI/NPCButtons/BtnPriestess
@onready var btn_go_combat      : Button  = $UI/NPCButtons/BtnGoCombat

var _dialogue_queue : Array[String] = []
var _current_speaker : String = ""

# ── LIFECYCLE ─────────────────────────────────────

func _ready():
	dialogue_box.hide()
	label_location.text = "Aula Kerajaan"

	btn_magician.pressed.connect(_talk_magician)
	btn_emperor.pressed.connect(_talk_emperor)
	btn_priestess.pressed.connect(_talk_priestess)
	btn_go_combat.pressed.connect(_on_go_combat)
	btn_next.pressed.connect(_advance_dialogue)
	btn_close.pressed.connect(_close_dialogue)

	# Reaksi NPC berubah subtle berdasarkan corruption tier
	_apply_npc_mood()

# ── NPC DIALOGUE ──────────────────────────────────

func _talk_magician():
	var tier = GameManager.get_corruption_tier()
	match tier:
		"jester":
			_open_dialogue("The Magician", [
				"Ah, si pelawak malam. Kau berlatih lagi tadi malam, bukan?",
				"Tanganmu... tidak seperti tangan badut biasa. Ada sesuatu yang kau sembunyikan.",
				"Aku tidak akan bertanya. Tapi jika kau butuh buku taktik — perpustakaanku terbuka.",
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
				"Badut! Sudah siang. Kau seharusnya menghibur, bukan berdiri melamun.",
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
	# High Priestess tidak pernah bicara banyak — dia tahu
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
				"*Atau mungkin memang tidak ada yang perlu dikatakan.*",
			])
		"joker":
			_open_dialogue("The High Priestess", [
				"*Ia berpaling darimu.*",
				"*Pertama kalinya.*",
			])

# ── NAVIGATION ────────────────────────────────────

func _on_go_combat():
	GameManager.combat_mode = "normal"
	get_tree().change_scene_to_file("res://scenes/CombatScene.tscn")

# ── DIALOGUE ENGINE ───────────────────────────────

func _open_dialogue(speaker: String, lines: Array[String]):
	_current_speaker = speaker
	_dialogue_queue = lines.duplicate()
	dialogue_box.show()
	_advance_dialogue()

func _advance_dialogue():
	if _dialogue_queue.is_empty():
		_close_dialogue()
		return
	label_speaker.text = _current_speaker
	label_text.text = _dialogue_queue.pop_front()

func _close_dialogue():
	dialogue_box.hide()
	_dialogue_queue.clear()

# ── MOOD ──────────────────────────────────────────

func _apply_npc_mood():
	# Visual subtle: tint warna NPC button berdasarkan tier
	# Bukan expose corruption — hanya "rasa" yang bergeser
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

func _on_go_boss():
	GameManager.combat_mode = "boss"
	get_tree().change_scene_to_file("res://scenes/CombatScene.tscn")
