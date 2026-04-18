class_name NPC
extends Node2D

@export var npc_name: String = "NPC"
@export var npc_type: String = "magician"  # "magician" | "emperor" | "priestess"
@onready var label: Label = $Label
@onready var indicator: Label = $Indicator

signal interaction_triggered(npc_type: String)

func _ready():
	add_to_group("npc")  
	label.text = npc_name
	indicator.visible = false

func interact():
	interaction_triggered.emit(npc_type)

func show_indicator():
	indicator.visible = true

func hide_indicator():
	indicator.visible = false
