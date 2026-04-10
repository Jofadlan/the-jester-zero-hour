extends Node

# Joker slots — maksimal 2
var joker_slots: Array = [null, null]

# Joker yang sudah ditemukan di world (belum tentu di slot)
var collected_jokers: Array = []

# Corruption meter (hidden)
var corruption: int = 0

# Gold
var gold: int = 0

var combat_mode: String = "normal"  # "normal" atau "boss"
var boss_stage_effects: Array = []  # efek per stage boss

func add_corruption(amount: int) -> void:
	corruption = clamp(corruption + amount, 0, 100)
	# Opsional: uncomment baris di bawah untuk sync lebih responsif
	UICorruptionTint.force_sync()

func get_corruption_tier() -> String:
	if corruption <= 39:
		return "jester"
	elif corruption <= 69:
		return "grey"
	else:
		return "joker"


func add_joker_to_collection(joker: JokerData) -> void:
	collected_jokers.append(joker)

func equip_joker(joker: JokerData, slot_index: int) -> void:
	# Cek apakah joker yang sama sudah ada di slot lain
	for i in joker_slots.size():
		if joker_slots[i] != null and joker_slots[i].joker_type == joker.joker_type:
			return  # Tolak — joker yang sama sudah terpasang
	
	# Kalau slot sudah ada isinya, buang yang lama permanen
	if joker_slots[slot_index] != null:
		collected_jokers.erase(joker_slots[slot_index])
	joker_slots[slot_index] = joker
	collected_jokers.erase(joker)
func unequip_joker(slot_index: int) -> void:
	# Buang Joker dari slot — hilang permanen
	joker_slots[slot_index] = null

func get_equipped_jokers() -> Array:
	var result = []
	for joker in joker_slots:
		if joker != null:
			result.append(joker)
	return result

func get_joker_count() -> int:
	var count = 0
	for joker in joker_slots:
		if joker != null:
			count += 1
	return count
