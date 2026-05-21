extends Node2D


func _ready():
	if GameManager.target_spawn_node != "":
			var player = get_tree().get_nodes_in_group("player")[0]
			var spawn_point = get_node_or_null(GameManager.target_spawn_node)
			if player and spawn_point:
				player.global_position = spawn_point.global_position
			GameManager.target_spawn_node = ""
