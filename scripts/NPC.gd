class_name NPC
extends Node2D

@export var npc_name: String = "NPC"
@export var npc_type: String = "magician"  # "magician" | "emperor" | "priestess"

@onready var label: Label = $Label
@onready var indicator: Label = $Indicator
@onready var interaction_zone: Area2D = $InteractionZone

signal interaction_triggered(npc_type: String)

func _ready():
	add_to_group("npc")
	label.text = npc_name
	indicator.visible = false

	# Connect zone ke player detection
	interaction_zone.body_entered.connect(_on_zone_body_entered)
	interaction_zone.body_exited.connect(_on_zone_body_exited)

# ── ZONE CALLBACKS (fallback jika Player pakai CharacterBody2D) ──

func _on_zone_body_entered(body: Node) -> void:
	if body.is_in_group("player") or body is CharacterBody2D:
		show_indicator()

func _on_zone_body_exited(body: Node) -> void:
	if body.is_in_group("player") or body is CharacterBody2D:
		hide_indicator()
		
var is_locked: bool = false

func set_locked(value: bool) -> void:
	is_locked = value
	if is_locked:
		modulate = Color(0.4, 0.4, 0.4, 1.0)
		indicator.text = "[?]"
	else:
		modulate = Color(1, 1, 1, 1)
		indicator.text = "[E]"

func show_indicator() -> void:
	indicator.visible = true

func hide_indicator() -> void:
	indicator.visible = false

# override interact check
func interact() -> void:
	if is_locked:
		return
	interaction_triggered.emit(npc_type)
