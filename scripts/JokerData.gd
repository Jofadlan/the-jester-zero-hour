class_name JokerData
extends Resource

enum JokerType {
	THE_INVISIBLE_SEMUT,
	HIDDEN_SINEW,
	TACTICIANS_SATIRE,
	THE_LATE_ARRIVAL,
	NIGHTLY_PROWESS,
	SHADOW_MENTOR,
	THE_OILY_TORCH,
	VAIN_PRESERVATION,
	NONE
}

enum JokerTier { BUFF, DEBUFF, NEUTRAL }

@export var joker_type: JokerType = JokerType.NIGHTLY_PROWESS
@export var tier: JokerTier = JokerTier.BUFF
@export var jp_cost: int = 1
@export var display_name: String = ""
@export var description: String = "???"  # Tersembunyi sampai di slot

# Apakah sudah dimasukkan ke slot (description terbuka)
var is_revealed: bool = false

func reveal() -> void:
	is_revealed = true

func get_description() -> String:
	if is_revealed:
		return description
	return "???"
