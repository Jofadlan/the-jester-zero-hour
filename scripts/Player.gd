extends CharacterBody2D

const KECEPATAN = 130.0
const INTERACT_RADIUS = 80.0  # pixel, sesuaikan jika perlu

var state: State
var states = {}
var vel = Vector2.ZERO
var arah_terakhir = Vector2.RIGHT

var _nearby_npc: Node = null

func _ready():
	states["idle"] = load("res://scripts/IdleState.gd").new()
	states["jalan"] = load("res://scripts/JalanState.gd").new()

	for s in states.values():
		s.player = self

	add_to_group("player")
	change_state("idle")

func get_animasi():
	return $AnimatedSprite2D

func change_state(new_state):
	if state:
		state.exit()
	state = states[new_state]
	state.enter()

func _input(event):
	state.handle_input(event)

	if event.is_action_pressed("interact"):
		var npc = _get_closest_npc()
		if npc != null:
			npc.interact()

func _process(delta):
	state.update(delta)
	_update_nearby_npc()

func _physics_process(delta):
	state.physics_update(delta)
	velocity = vel
	move_and_slide()

# ── NPC DETECTION VIA DISTANCE ─────────────────────

func _get_closest_npc() -> Node:
	var closest: Node = null
	var closest_dist := INTERACT_RADIUS

	for npc in get_tree().get_nodes_in_group("NPCs"):
		var dist = global_position.distance_to(npc.global_position)
		print("tes")
		if dist < closest_dist:
			closest_dist = dist
			closest = npc

	return closest

func _update_nearby_npc() -> void:
	var npc = _get_closest_npc()

	if npc != _nearby_npc:
		# Hide indicator NPC lama
		if _nearby_npc != null and _nearby_npc.has_method("hide_indicator"):
			_nearby_npc.hide_indicator()

		_nearby_npc = npc

		# Show indicator NPC baru
		if _nearby_npc != null and _nearby_npc.has_method("show_indicator"):
			_nearby_npc.show_indicator()
