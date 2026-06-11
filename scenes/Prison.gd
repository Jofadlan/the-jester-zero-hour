extends Node2D

@onready var boss_area  : Node2D  = $BossArea
@onready var boss_label : Label   = $BossArea/BossLabel
@onready var boss_zone  : Area2D  = $BossArea/BossZone

@onready var boss_dialogue_panel : PanelContainer = $UIPopUp/BossDialoguePanel
@onready var boss_dialogue_text  : Label          = $UIPopUp/BossDialoguePanel/Vbox/BossText
@onready var btn_boss_confirm    : Button         = $UIPopUp/BossDialoguePanel/Vbox/BtnConfirm

func _ready():
	$StairExit.body_entered.connect(_on_stair_exit_body_entered)
	if GameManager.target_spawn_node != "":
		var player = get_tree().get_nodes_in_group("player")[0]
		var spawn_point = get_node_or_null(GameManager.target_spawn_node)
		if player and spawn_point:
			player.global_position = spawn_point.global_position
		GameManager.target_spawn_node = ""

	boss_dialogue_panel.hide()
	btn_boss_confirm.pressed.connect(_on_boss_confirm)
	boss_zone.body_entered.connect(_on_boss_zone_entered)
	_refresh_boss_area()



func _on_stair_exit_body_entered(body):
	if body.is_in_group("player"):
		get_tree().change_scene_to_file("res://scenes/RoyalHall.tscn")

func _refresh_boss_area() -> void:
	var unlocked = GameManager.normal_combat_cleared
	boss_label.text = "[ The Lovers ]" if unlocked else "[ ??? ]"
	boss_area.modulate = Color(1, 1, 1, 1) if unlocked else Color(0.35, 0.3, 0.3, 1)

func _on_boss_zone_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if not GameManager.normal_combat_cleared:
		return
	_show_boss_dialogue()

func _show_boss_dialogue() -> void:
	boss_dialogue_text.text = (
		"*Suara itu terdengar lebih berat dari sebelumnya...*\n\n" +
		"\"Kau sudah sampai di sini.\n\n" +
		"Yang ada di balik pintu itu bukan musuh biasa. " +
		"Ia adalah cerminan dari pilihan yang belum pernah kau buat — " +
		"dan semua yang ingin kau hindari dari dirimu sendiri.\n\n" +
		"Apakah kau siap menghadapinya?\""
	)
	boss_dialogue_panel.show()

func _on_boss_confirm() -> void:
	boss_dialogue_panel.hide()
	GameManager.combat_mode = "boss"
	get_tree().change_scene_to_file("res://scenes/CombatScene.tscn")
