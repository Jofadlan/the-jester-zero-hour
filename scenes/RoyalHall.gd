extends Node2D

const INTERACT_RADIUS = 100.0

@onready var dialogue_box   : Control = $UI/DialogueBox
@onready var label_speaker  : Label   = $UI/DialogueBox/VBox/LabelSpeaker
@onready var label_text     : Label   = $UI/DialogueBox/VBox/LabelText
@onready var btn_next       : Button  = $UI/DialogueBox/VBox/HBox/BtnNext
@onready var btn_close      : Button  = $UI/DialogueBox/VBox/HBox/BtnClose
@onready var btn_go_boss    : Button  = $UI/BtnGoBoss

var _dialogue_queue : Array[String] = []
var _current_speaker: String = ""
var _player: Node = null

func _ready():
	# Pastikan UI visible
	$UI.visible = true
	dialogue_box.hide()
	btn_go_boss.hide()

	btn_next.pressed.connect(_advance_dialogue)
	btn_close.pressed.connect(_close_dialogue)

	if GameManager.tutorial_done:
		btn_go_boss.show()

	# Cari player
	await get_tree().process_frame
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0]
	else:
		# Fallback — cari by class
		_player = $Player if has_node("Player") else null

func _process(_delta):
	if _player == null:
		return

	# Update NPC indicators berdasarkan jarak
	for npc in get_tree().get_nodes_in_group("npc"):
		var dist = _player.global_position.distance_to(npc.global_position)
		if dist < INTERACT_RADIUS:
			npc.show_indicator()
		else:
			npc.hide_indicator()

func _input(event):
	# Tutup dialogue dengan E atau close button
	if event.is_action_pressed("interact") and dialogue_box.visible:
		_advance_dialogue()
		return

	# Buka dialogue
	if event.is_action_pressed("interact") and not dialogue_box.visible:
		if _player == null:
			return
		_try_interact()

func _try_interact():
	var closest_npc: Node = null
	var closest_dist := INTERACT_RADIUS

	for npc in get_tree().get_nodes_in_group("npc"):
		var dist = _player.global_position.distance_to(npc.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest_npc = npc

	if closest_npc == null:
		return

	match closest_npc.npc_type:
		"magician":  _talk_magician()
		"emperor":   _talk_emperor()
		"priestess": _talk_priestess()

# ── DIALOGUE ──────────────────────────────────────

func _open_dialogue(speaker: String, lines: Array[String]):
	_current_speaker = speaker
	_dialogue_queue   = lines.duplicate()
	dialogue_box.show()
	_advance_dialogue()

func _advance_dialogue():
	if _dialogue_queue.is_empty():
		_close_dialogue()
		return
	label_speaker.text = _current_speaker
	label_text.text    = _dialogue_queue.pop_front()

func _close_dialogue():
	dialogue_box.hide()
	_dialogue_queue.clear()

# ── NPC TALKS ─────────────────────────────────────

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
