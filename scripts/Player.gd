class_name Player
extends CharacterBody2D

const SPEED = 200.0
const INTERACTION_RANGE = 80.0

@onready var sprite: ColorRect = $Sprite

var nearest_npc = null

func _physics_process(_delta):
	var direction = 0
	if Input.is_action_pressed("ui_left"):
		direction = -1
		sprite.scale.x = -1
	elif Input.is_action_pressed("ui_right"):
		direction = 1
		sprite.scale.x = 1
	
	velocity.x = direction * SPEED
	velocity.y = 0
	move_and_slide()
	
	_check_nearest_npc()

func _check_nearest_npc():
	var npcs = get_tree().get_nodes_in_group("npc")
	var closest = null
	var closest_dist = INTERACTION_RANGE
	
	for npc in npcs:
		var dist = global_position.distance_to(npc.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = npc
	
	# Update indicator
	if closest != nearest_npc:
		if nearest_npc != null:
			nearest_npc.hide_indicator()
		nearest_npc = closest
		if nearest_npc != null:
			nearest_npc.show_indicator()

func _unhandled_input(event):
	if event.is_action_pressed("interact") and nearest_npc != null:
		nearest_npc.interact()
