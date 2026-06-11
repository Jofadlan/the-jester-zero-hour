extends Node2D

@onready var text_label : Label  = $UI/Panel/VBox/TextLabel
@onready var btn_next   : Button = $UI/Panel/VBox/BtnNext

var _index: int = 0

const SLIDES: Array[String] = [
	"*Langit merah perlahan memudar...*\n\n\"Kau telah menghadapi cerminanmu sendiri.\nDan kau masih berdiri.\n\nUntuk saat ini.\"",

	"*The Lovers (VI) — dikalahkan.*\n\nBukan karena kau lebih kuat.\nTapi karena kau belum selesai.",

	"*Suara itu terdengar lebih jauh dari biasanya...*\n\n\"Perjalanan ini baru saja dimulai.\nMasih ada dua puluh tahun yang harus kau jalani.\n\nDan pilihan-pilihan yang belum kau buat.\"",

	"*Keheningan.*\n\n\"Kau tahu apa yang lucu dari semua ini?\n\nKau masih belum tahu siapa kau sebenarnya.\"\n\n— The World (XXI)",
]

func _ready() -> void:
	btn_next.pressed.connect(_on_next)
	text_label.text = SLIDES[0]
	btn_next.text = "Lanjut ▶"

func _on_next() -> void:
	_index += 1
	if _index >= SLIDES.size():
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
		return
	text_label.text = SLIDES[_index]
	if _index == SLIDES.size() - 1:
		btn_next.text = "Selesai"
