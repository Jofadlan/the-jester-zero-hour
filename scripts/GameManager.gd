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

# Joker Discovery — lokasi sesuai PRD
const JOKER_LOCATIONS: Dictionary = {
	JokerData.JokerType.THE_INVISIBLE_SEMUT: "alchemy_room",
	JokerData.JokerType.HIDDEN_SINEW:        "armory",
	JokerData.JokerType.TACTICIANS_SATIRE:   "alchemy_room",
	JokerData.JokerType.THE_LATE_ARRIVAL:    "market",
	JokerData.JokerType.NIGHTLY_PROWESS:     "back_courtyard",
	JokerData.JokerType.SHADOW_MENTOR:       "library",
	JokerData.JokerType.THE_OILY_TORCH:      "border_village",
	JokerData.JokerType.VAIN_PRESERVATION:   "border_village",
	JokerData.JokerType.NONE:                "gambling_den",
}

# Track status per Joker
var joker_discovery_state: Dictionary = {}

func _ready() -> void:
	_init_discovery_state()

func _init_discovery_state() -> void:
	for joker_type in JOKER_LOCATIONS.keys():
		joker_discovery_state[joker_type] = {
			"found": false,
			"gone": false
		}

## Dipanggil saat player memasuki area dan berinteraksi.
## Mengembalikan JokerData jika berhasil, null jika sudah diambil/hilang.
func try_discover_joker(joker_type: JokerData.JokerType) -> JokerData:
	var state = joker_discovery_state.get(joker_type, null)
	if state == null or state["found"] or state["gone"]:
		return null
	
	state["found"] = true
	var joker = JokerFactory.create_by_type(joker_type)
	add_joker_to_collection(joker)
	return joker

## Dipanggil saat story progression mengubah sebuah area.
## Semua Joker yang belum diambil di area itu hilang permanen.
func expire_jokers_in_area(area_id: String) -> void:
	for joker_type in JOKER_LOCATIONS.keys():
		if JOKER_LOCATIONS[joker_type] == area_id:
			var state = joker_discovery_state[joker_type]
			if not state["found"]:
				state["gone"] = true

## Query — untuk UI area: apakah masih ada Joker di sini?
func has_undiscovered_joker(area_id: String) -> bool:
	for joker_type in JOKER_LOCATIONS.keys():
		if JOKER_LOCATIONS[joker_type] == area_id:
			var state = joker_discovery_state[joker_type]
			if not state["found"] and not state["gone"]:
				return true
	return false

var tutorial_done: bool = false

func complete_tutorial():
	tutorial_done = true
