extends Node2D

@onready var panel: PanelContainer = $UI/Panel
@onready var text_label: Label = $UI/Panel/VBox/TextLabel
@onready var btn_next: Button = $UI/Panel/VBox/BtnNext
@onready var btn_skip: Button = $UI/Panel/VBox/BtnSkip

var _index: int = 0

const SLIDES: Array[String] = [
	"*Suara muncul dari tempat yang tidak bisa kau tunjuk...*\n\n\"Selamat datang, Jester.\n\nKau baru saja menyaksikan dunia hancur. Dan kini kau kembali — dua puluh tahun sebelumnya — dengan ingatan yang seharusnya tidak kau miliki.\"",
	"\"Bergeraklah dengan WASD atau tombol panah.\n\nJika ada NPC di dekatmu, indikator [E] akan muncul. Tekan E untuk berbicara.\n\nMereka belum tahu apa yang kau tahu. Jaga itu.\"",
	"\"Kau akan bertarung. Bukan dengan pedang — dengan kartu.\n\nBentuk kombinasi poker terbaik dari 7 kartu yang diberikan. Skor terakumulasi hingga mencapai target.\n\nJika gagal... ada konsekuensinya.\"",
	"*Suara itu memudar, hampir seperti tidak pernah ada*\n\n\"Aku tidak bisa memberitahumu apa yang benar. Tidak ada yang bisa.\n\nYang bisa kulakukan hanya menemanimu — sampai kau tidak membutuhkanku lagi.\n\nAtau sampai semuanya berakhir. Lagi.\""
]

func _ready() -> void:
	if GameManager.tutorial_done:
		_go_to_royal_hall()
		return
	
	btn_next.pressed.connect(_on_next)
	btn_skip.pressed.connect(_on_skip)
	text_label.text = SLIDES[0]
	btn_next.text = "Lanjut ▶"
	btn_skip.text = "Lewati"

func _on_skip() -> void:
	GameManager.complete_tutorial()
	_go_to_royal_hall()
	
func _on_next() -> void:
	_index += 1
	if _index >= SLIDES.size():
		GameManager.tutorial_done = true
		_go_to_royal_hall()
		return
	
	text_label.text = SLIDES[_index]
	if _index == SLIDES.size() - 1:
		btn_next.text = "Aku mengerti"

func _go_to_royal_hall() -> void:
	get_tree().change_scene_to_file("res://scenes/RoyalHall.tscn")
