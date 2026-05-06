extends Node2D

const INTERACT_RADIUS = 100.0

@onready var dialogue_box   : Control = $UI/DialogueBox
@onready var label_speaker  : Label   = $UI/DialogueBox/VBox/LabelSpeaker
@onready var label_text     : Label   = $UI/DialogueBox/VBox/LabelText
@onready var btn_next       : Button  = $UI/DialogueBox/VBox/HBox/BtnNext
@onready var btn_close      : Button  = $UI/DialogueBox/VBox/HBox/BtnClose

# Choice buttons — tambahkan 2 button ini di DialogueBox/VBox/HBox di scene
@onready var btn_choice_1   : Button  = $UI/DialogueBox/VBox/HBox/BtnChoice1
@onready var btn_choice_2   : Button  = $UI/DialogueBox/VBox/HBox/BtnChoice2

var _dialogue_queue  : Array[String] = []
var _current_speaker : String = ""
var _player          : Node   = null
var _pending_choices : Array  = []  # [{text, callable}]

func _ready():
	$UI.visible = true
	dialogue_box.hide()

	btn_next.pressed.connect(_advance_dialogue)
	btn_close.pressed.connect(_close_dialogue)
	btn_choice_1.pressed.connect(_on_choice_pressed.bind(0))
	btn_choice_2.pressed.connect(_on_choice_pressed.bind(1))

	btn_choice_1.hide()
	btn_choice_2.hide()

	await get_tree().process_frame
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0]

func _process(_delta):
	if _player == null:
		return
	for npc in get_tree().get_nodes_in_group("npc"):
		var dist = _player.global_position.distance_to(npc.global_position)
		if dist < INTERACT_RADIUS:
			npc.show_indicator()
		else:
			npc.hide_indicator()

func _input(event):
	if event.is_action_pressed("interact") and dialogue_box.visible and _pending_choices.is_empty():
		_advance_dialogue()
		return

	if event.is_action_pressed("interact") and not dialogue_box.visible:
		_try_interact()

# ── INTERACTION ────────────────────────────────────

func _try_interact():
	if _player == null:
		return

	var closest_npc : Node  = null
	var closest_dist: float = INTERACT_RADIUS

	for npc in get_tree().get_nodes_in_group("npc"):
		var dist = _player.global_position.distance_to(npc.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest_npc  = npc

	if closest_npc == null:
		return

	match closest_npc.npc_type:
		"magician":  _talk_magician()
		"emperor":   _talk_emperor()
		"priestess": _talk_priestess()

# ── DIALOGUE ENGINE ────────────────────────────────

func _open_dialogue(speaker: String, lines: Array[String], choices: Array = []):
	_current_speaker  = speaker
	_dialogue_queue   = lines.duplicate()
	_pending_choices  = choices
	btn_next.show()
	btn_close.show()
	btn_choice_1.hide()
	btn_choice_2.hide()
	dialogue_box.show()
	_advance_dialogue()

func _advance_dialogue():
	if not _dialogue_queue.is_empty():
		label_speaker.text = _current_speaker
		label_text.text    = _dialogue_queue.pop_front()

		# Kalau ini line terakhir dan ada choices, tampilkan choices
		if _dialogue_queue.is_empty() and not _pending_choices.is_empty():
			_show_choices()
		return

	# Queue habis dan tidak ada choices — tutup
	if _pending_choices.is_empty():
		_close_dialogue()

func _show_choices():
	btn_next.hide()
	btn_close.hide()

	if _pending_choices.size() >= 1:
		btn_choice_1.text = _pending_choices[0]["text"]
		btn_choice_1.show()

	if _pending_choices.size() >= 2:
		btn_choice_2.text = _pending_choices[1]["text"]
		btn_choice_2.show()

func _on_choice_pressed(index: int):
	if index >= _pending_choices.size():
		return

	var choice = _pending_choices[index]
	_pending_choices = []
	btn_choice_1.hide()
	btn_choice_2.hide()
	_close_dialogue()

	# Jalankan aksi setelah dialogue tutup
	if choice.has("action"):
		choice["action"].call()

func _close_dialogue():
	dialogue_box.hide()
	_dialogue_queue.clear()
	_pending_choices = []
	btn_next.show()
	btn_close.show()
	btn_choice_1.hide()
	btn_choice_2.hide()

# ── NPC TALKS ─────────────────────────────────────

func _talk_magician():
	var tier = GameManager.get_corruption_tier()
	match tier:
		"jester":
			_open_dialogue("The Magician", [
				"Ah, si pelawak malam. Kau berlatih lagi tadi malam, bukan?",
				"Tanganmu... tidak seperti tangan badut biasa.",
				"Malam ini — apakah kau ingin berlatih lagi?",
			], [
				{
					"text": "\"Iya. Aku butuh berlatih.\"",
					"action": Callable(self, "_go_combat_normal")
				},
				{
					"text": "\"Ceritakan tentang The Lovers.\"",
					"action": Callable(self, "_go_combat_boss")
				},
			])
		"grey":
			_open_dialogue("The Magician", [
				"Matamu semakin berat hari ini.",
				"Aku pernah melihat mata seperti itu. Orang yang menanggung sesuatu terlalu lama.",
				"...Apakah kau masih ingin berlatih? Dalam kondisi seperti ini?",
			], [
				{
					"text": "\"Justru itulah aku harus berlatih.\"",
					"action": Callable(self, "_go_combat_normal")
				},
				{
					"text": "\"Tidak. Aku hanya ingin bicara.\"",
					"action": func(): pass
				},
			])
		"joker":
			# Corruption tinggi — Magician menolak melatih
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

# ── COMBAT TRANSITIONS ────────────────────────────

func _go_combat_normal():
	GameManager.combat_mode = "normal"
	get_tree().change_scene_to_file("res://scenes/CombatScene.tscn")

func _go_combat_boss():
	GameManager.combat_mode = "boss"
	get_tree().change_scene_to_file("res://scenes/CombatScene.tscn")
