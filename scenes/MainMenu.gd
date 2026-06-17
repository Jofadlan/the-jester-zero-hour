extends Node2D

@onready var btn_story   : Button = $UI/VBox/BtnStory
@onready var btn_endless : Button = $UI/VBox/BtnEndless
@onready var btn_quit    : Button = $UI/VBox/BtnQuit

func _ready() -> void:
	btn_quit.grab_focus()
	btn_endless.grab_focus()
	btn_story.grab_focus()
	btn_story.pressed.connect(_on_story)
	btn_endless.pressed.connect(_on_endless)
	btn_quit.pressed.connect(_on_quit)

func _on_story() -> void:
	GameManager.combat_mode = "normal"
	GameManager.reset_progress()
	get_tree().change_scene_to_file("res://scenes/TutorialScene.tscn")

func _on_endless() -> void:
	GameManager.combat_mode = "normal"
	get_tree().change_scene_to_file("res://scenes/CombatScene.tscn")

func _on_quit() -> void:
	get_tree().quit()
