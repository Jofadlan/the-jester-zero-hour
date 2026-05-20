extends Node2D

const INTERACT_RADIUS = 100.0

@onready var dialogue_box   : Control = $UI/DialogueBox
@onready var label_speaker  : Label   = $UI/DialogueBox/VBox/LabelSpeaker
@onready var label_text     : Label   = $UI/DialogueBox/VBox/LabelText
@onready var btn_next       : Button  = $UI/DialogueBox/VBox/HBox/BtnNext
@onready var btn_close      : Button  = $UI/DialogueBox/VBox/HBox/BtnClose
@onready var btn_choice_1   : Button  = $UI/DialogueBox/VBox/HBox/BtnChoice1
@onready var btn_choice_2   : Button  = $UI/DialogueBox/VBox/HBox/BtnChoice2
@onready var boss_area      : Node2D  = $BossArea
@onready var boss_label     : Label   = $BossArea/BossLabel
@onready var boss_zone      : Area2D  = $BossArea/BossZone
@onready var task_label     : RichTextLabel = $UIPopUp/TaskTracker
@onready var popup_panel    : PanelContainer = $UIPopUp/PopupPanel
@onready var popup_text     : Label = $UIPopUp/PopupPanel/Vbox/PopupText
@onready var btn_popup_close: Button = $UIPopUp/PopupPanel/Vbox/BtnClose
@onready var boss_dialogue_panel  : PanelContainer = $UIPopUp/BossDialoguePanel
@onready var boss_dialogue_text   : Label = $UIPopUp/BossDialoguePanel/Vbox/BossText
@onready var btn_boss_confirm     : Button = $UIPopUp/BossDialoguePanel/Vbox/BtnConfirm

var _dialogue_queue  : Array[String] = []
var _current_speaker : String = ""
var _player          : Node   = null
var _pending_choices : Array  = []

func _ready():
	$UI.visible = true
	dialogue_box.hide()
	popup_panel.hide()
	boss_dialogue_panel.hide()

	btn_next.pressed.connect(_advance_dialogue)
	btn_close.pressed.connect(_close_dialogue)
	btn_choice_1.pressed.connect(_on_choice_pressed.bind(0))
	btn_choice_2.pressed.connect(_on_choice_pressed.bind(1))
	btn_choice_1.hide()
	btn_choice_2.hide()

	btn_popup_close.pressed.connect(func(): popup_panel.hide())
	btn_boss_confirm.pressed.connect(_on_boss_confirm)
	boss_zone.body_entered.connect(_on_boss_zone_entered)

	_refresh_npc_states()
	_refresh_boss_area()
	_refresh_task_tracker()
	btn_next.pressed.connect(_advance_dialogue)
	btn_close.pressed.connect(_close_dialogue)
	btn_choice_1.pressed.connect(_on_choice_pressed.bind(0))
	btn_choice_2.pressed.connect(_on_choice_pressed.bind(1))
	btn_choice_1.hide()
	btn_choice_2.hide()

	boss_zone.body_entered.connect(_on_boss_zone_entered)

	_refresh_npc_states()
	_refresh_boss_area()

func _on_ready_deferred() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0]

func _notification(what):
	if what == NOTIFICATION_READY:
		call_deferred("_on_ready_deferred")
		
func _refresh_npc_states() -> void:
	var magician = _get_npc("magician")
	var emperor  = _get_npc("emperor")
	var priestess = _get_npc("priestess")

	if priestess:
		priestess.set_locked(false)  # selalu unlock duluan
	if emperor:
		emperor.set_locked(not GameManager.talked_to_priestess)
	if magician:
		magician.set_locked(not GameManager.talked_to_emperor)

func _refresh_boss_area() -> void:
	var unlocked = GameManager.normal_combat_cleared
	boss_label.text = "[ The Lovers ]" if unlocked else "[ ??? ]"
	boss_area.modulate = Color(1, 1, 1, 1) if unlocked else Color(0.35, 0.3, 0.3, 1)

func _get_npc(type: String) -> Node:
	for npc in get_tree().get_nodes_in_group("npc"):
		if npc.npc_type == type:
			return npc
	return null

func _process(_delta):
	if _player == null:
		return
	for npc in get_tree().get_nodes_in_group("npc"):
		if npc.is_locked:
			npc.hide_indicator()
			continue
		var dist = _player.global_position.distance_to(npc.global_position)
		if dist < INTERACT_RADIUS:
			npc.show_indicator()
		else:
			npc.hide_indicator()

func _on_boss_zone_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if not GameManager.normal_combat_cleared:
		return
	_show_boss_dialogue()

func _show_boss_dialogue() -> void:
	boss_dialogue_text.text = "*Suara itu terdengar lebih berat dari sebelumnya...*\n\n\"Kau sudah sampai di sini.\n\nYang ada di balik pintu itu bukan musuh biasa. Ia adalah cerminan dari pilihan yang belum pernah kau buat — dan semua yang ingin kau hindari dari dirimu sendiri.\n\nApakah kau siap menghadapinya?\""
	boss_dialogue_panel.show()

func _on_boss_confirm() -> void:
	boss_dialogue_panel.hide()
	_go_combat_boss()
	
func _input(event):
	if event.is_action_pressed("interact") and dialogue_box.visible and _pending_choices.is_empty():
		_advance_dialogue()
		return
	if event.is_action_pressed("interact") and not dialogue_box.visible:
		_try_interact()

func _try_interact():
	if _player == null:
		return
	var closest_npc : Node  = null
	var closest_dist: float = INTERACT_RADIUS
	for npc in get_tree().get_nodes_in_group("npc"):
		if npc.is_locked:
			continue
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

# ── NPC TALKS ─────────────────────────────────────

func _talk_priestess():
	var tier = GameManager.get_corruption_tier()
	var lines: Array[String] = []
	match tier:
		"jester":
			lines = [
				"...",
				"*Sang Peramal Bisu menatapmu — bukan dengan heran, tapi dengan sesuatu yang menyerupai pengenalan.*",
				"*Seperti ia sudah pernah melihat matamu sebelumnya. Berkali-kali.*",
				"*Tanpa kata, tanpa penjelasan, ia menyodorkan sebuah kartu ke tanganmu.*",
				"*Nightly Prowess — kekuatan yang hanya muncul di kegelapan.*",
				"*Ia berpaling. Audiensmu sudah selesai.*",
			]
		"grey":
			lines = [
				"...",
				"*Ia mengulurkan tangan sejenak — lalu berhenti.*",
				"*Matanya membaca sesuatu di wajahmu yang bahkan kau sendiri belum menyadarinya.*",
				"*Akhirnya ia menyerahkan kartu itu. Dengan ekspresi yang tidak bisa kau baca.*",
				"*Nightly Prowess. Hadiah, atau peringatan — kau tidak tahu.*",
			]
		"joker":
			lines = [
				"*Ia berpaling saat kau mendekat.*",
				"*Pertama kalinya.*",
				"*Namun tangannya — seperti gerak refleks — masih menyodorkan kartu itu ke belakang.*",
				"*Nightly Prowess. Mungkin kebiasaan lama yang tidak bisa ia hentikan.*",
			]

	_open_dialogue("The High Priestess", lines, [], func():
		if not GameManager.talked_to_priestess:
			_give_joker_to_player(JokerData.JokerType.NIGHTLY_PROWESS)
			GameManager.complete_talk("priestess")
			_refresh_npc_states()
			_refresh_task_tracker()
			_show_popup(POPUP_TEXTS["priestess_done"])
	)

func _talk_emperor():
	var tier = GameManager.get_corruption_tier()
	var lines: Array[String] = []
	match tier:
		"jester":
			lines = [
				"Badut! Sudah siang. Kau seharusnya menghibur, bukan melamun.",
				"...",
				"*Raja menatapmu lebih lama dari biasanya. Sesuatu di matamu membuatnya terdiam.*",
				"\"Kau tampak berbeda hari ini. Lebih... berat.\"",
				"*Dengan gerakan yang hampir terlihat malas, ia mendorong sesuatu ke tepi meja.*",
				"\"Ambil itu. Jangan tanya kenapa. Dan jangan ganggu aku lagi.\"",
				"*The Oily Torch — obor yang membakar lebih terang, tapi juga membakar lebih jauh.*",
			]
		"grey":
			lines = [
				"Kau tampak aneh belakangan ini.",
				"Para penasihat mulai membicarakanmu. Badut yang terlalu banyak tahu.",
				"*Ia membuka laci mejanya. Mengambil sesuatu.*",
				"\"Aku tidak tahu mengapa aku melakukan ini. Mungkin karena kau satu-satunya yang masih terlihat... peduli.\"",
				"*The Oily Torch berpindah tangan.*",
				"\"Gunakan dengan bijak. Atau jangan gunakan sama sekali.\"",
			]
		"joker":
			lines = [
				"Aku tidak mau melihatmu hari ini.",
				"*Namun amplop di mejanya sudah disiapkan — seolah ia tahu kau akan datang.*",
				"\"Ambil. Pergi. Jangan kembali sampai kau punya alasan yang lebih baik untuk ada di sini.\"",
				"*The Oily Torch. Bahkan dalam kemarahannya, ia masih menyiapkan ini.*",
			]

	_open_dialogue("The Emperor", lines, [], func():
		if not GameManager.talked_to_emperor:
			_give_joker_to_player(JokerData.JokerType.THE_OILY_TORCH)
			GameManager.complete_talk("emperor")
			_refresh_npc_states()
			_refresh_task_tracker()
			_show_popup(POPUP_TEXTS["emperor_done"])
	)
	
func _talk_magician():
	var tier = GameManager.get_corruption_tier()
	var lines: Array[String] = []
	match tier:
		"jester":
			lines = [
				"Ah, si pelawak malam.",
				"*Sang Alkemis tidak menyapamu seperti biasa. Ia menatap tanganmu.*",
				"\"Tangan itu... sudah berbeda dari terakhir kali. Kau berlatih.\"",
				"\"Aku tidak tahu apa yang kau tanggung. Tapi aku tahu cara membantumu mempersiapkan diri.\"",
				"\"Latihan malam — lawan dirimu sendiri dulu sebelum menghadapi yang lebih besar.\"",
			]
		"grey":
			lines = [
				"Matamu semakin berat hari ini.",
				"\"Aku pernah melihat mata seperti itu. Orang yang menanggung sesuatu terlalu lama.*",
				"\"Latihan tidak akan menghapus beban itu. Tapi mungkin... bisa memberimu cara untuk membawanya.\"",
			]
		"joker":
			lines = [
				"...",
				"\"Kau masih di sini.\"",
				"\"Aku kira kau sudah pergi ke tempat yang tidak bisa aku ikuti.\"",
				"\"Latihan masih tersedia. Jika kau masih mau.\"",
			]

	_open_dialogue("The Magician", lines, [
		{
			"text": "\"Iya. Aku siap.\"",
			"action": Callable(self, "_go_combat_normal")
		},
		{
			"text": "\"Belum sekarang.\"",
			"action": func(): pass
		},
	], func():
		if not GameManager.talked_to_magician:
			GameManager.complete_talk("magician")
			_refresh_task_tracker()
	)

func _give_joker_to_player(type: JokerData.JokerType) -> void:
	# Cari slot kosong
	for i in 2:
		if GameManager.joker_slots[i] == null:
			var joker = JokerFactory.create_by_type(type)
			joker.reveal()
			GameManager.joker_slots[i] = joker
			return
	# Kalau penuh, replace slot 0
	var joker = JokerFactory.create_by_type(type)
	joker.reveal()
	GameManager.joker_slots[0] = joker

# ── DIALOGUE ENGINE ────────────────────────────────

var _on_dialogue_end: Callable = Callable()

func _open_dialogue(speaker: String, lines: Array[String], choices: Array = [], on_end: Callable = Callable()) -> void:
	_current_speaker  = speaker
	_dialogue_queue   = lines.duplicate()
	_pending_choices  = choices
	_on_dialogue_end  = on_end
	btn_next.show()
	btn_close.show()
	btn_choice_1.hide()
	btn_choice_2.hide()
	dialogue_box.show()
	_advance_dialogue()

func _close_dialogue():
	dialogue_box.hide()
	_dialogue_queue.clear()
	_pending_choices = []
	btn_next.show()
	btn_close.show()
	btn_choice_1.hide()
	btn_choice_2.hide()
	if _on_dialogue_end.is_valid():
		_on_dialogue_end.call()
		_on_dialogue_end = Callable()
func _advance_dialogue():
	if not _dialogue_queue.is_empty():
		label_speaker.text = _current_speaker
		label_text.text    = _dialogue_queue.pop_front()
		if _dialogue_queue.is_empty() and not _pending_choices.is_empty():
			_show_choices()
		return
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
	if choice.has("action"):
		choice["action"].call()

	dialogue_box.hide()
	_dialogue_queue.clear()
	_pending_choices = []
	btn_next.show()
	btn_close.show()
	btn_choice_1.hide()
	btn_choice_2.hide()

# ── COMBAT TRANSITIONS ────────────────────────────

func _go_combat_normal():
	GameManager.combat_mode = "normal"
	get_tree().change_scene_to_file("res://scenes/CombatScene.tscn")

func _go_combat_boss():
	GameManager.combat_mode = "boss"
	get_tree().change_scene_to_file("res://scenes/CombatScene.tscn")

func _refresh_task_tracker() -> void:
	var lines: Array[String] = []
	
	_add_task(lines, "Temui The High Priestess", GameManager.talked_to_priestess, not GameManager.talked_to_priestess)
	_add_task(lines, "Temui The Emperor", GameManager.talked_to_emperor, GameManager.talked_to_priestess and not GameManager.talked_to_emperor)
	_add_task(lines, "Temui The Magician", GameManager.talked_to_magician, GameManager.talked_to_emperor and not GameManager.talked_to_magician)
	_add_task(lines, "Latihan Malam", GameManager.normal_combat_cleared, GameManager.talked_to_magician and not GameManager.normal_combat_cleared)
	_add_task(lines, "???", false, false) if not GameManager.normal_combat_cleared else _add_task(lines, "Hadapi The Lovers", false, true)
	
	task_label.text = "\n".join(lines)

func _add_task(lines: Array, text: String, done: bool, active: bool) -> void:
	if done:
		lines.append("[color=#555555][s]" + text + "[/s][/color]")
	elif active:
		lines.append("[color=#C99229]▶ " + text + "[/color]")
	else:
		lines.append("[color=#333333]  " + text + "[/color]")

func _show_popup(text: String) -> void:
	popup_text.text = text
	popup_panel.show()

const POPUP_TEXTS = {
	"priestess_done": "*Suara dari antah berantah...*\n\n\"Ia tidak berkata apa-apa. Tapi tangannya menyodorkan sesuatu.\nMungkin ia tahu lebih banyak dari yang ia tunjukkan.\n\nTemui Raja selanjutnya.\"",
	"emperor_done": "*Suara itu kembali...*\n\n\"Bahkan yang paling keras pun kadang menyerahkan sesuatu tanpa alasan yang jelas.\n\nCari Sang Alkemis. Ia menunggumu.\"",
	"magician_done": "*Berbisik pelan...*\n\n\"Ia melihat tanganmu. Tangan yang sudah berubah.\n\nLatihan menunggumu di luar. Buktikan bahwa kau lebih dari sekadar badut.\"",
	"combat_cleared": "*Sesuatu bergeser di udara...*\n\n\"Kau sudah membuktikannya pada dirimu sendiri.\n\nAda sesuatu di ujung sana yang menunggumu. Kau tahu apa itu.\""
}
