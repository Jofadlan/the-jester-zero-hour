class_name JokerFactory
extends RefCounted

static func create_nightly_prowess() -> JokerData:
	var joker = JokerData.new()
	joker.joker_type = JokerData.JokerType.NIGHTLY_PROWESS
	joker.tier = JokerData.JokerTier.BUFF
	joker.jp_cost = 2
	joker.display_name = "Nightly Prowess"
	joker.description = "Semua kartu di hand berikutnya dianggap satu tier lebih tinggi."
	return joker

static func create_oily_torch() -> JokerData:
	var joker = JokerData.new()
	joker.joker_type = JokerData.JokerType.THE_OILY_TORCH
	joker.tier = JokerData.JokerTier.DEBUFF
	joker.jp_cost = 1
	joker.display_name = "The Oily Torch"
	joker.description = "Skor hand ini ×2 — tapi target skor stage berikutnya juga ×2."
	return joker

static func create_invisible_semut() -> JokerData:
	var j = JokerData.new()
	j.joker_type = JokerData.JokerType.THE_INVISIBLE_SEMUT
	j.tier = JokerData.JokerTier.BUFF
	j.jp_cost = 1
	j.display_name = "The Invisible Semut"
	j.description = "Satu hand diabaikan oleh scoring penalty musuh."
	return j

static func create_hidden_sinew() -> JokerData:
	var j = JokerData.new()
	j.joker_type = JokerData.JokerType.HIDDEN_SINEW
	j.tier = JokerData.JokerTier.BUFF
	j.jp_cost = 2
	j.display_name = "Hidden Sinew"
	j.description = "Bonus skor untuk kombinasi yang melibatkan kartu rendah (2–5)."
	return j

static func create_tacticians_satire() -> JokerData:
	var j = JokerData.new()
	j.joker_type = JokerData.JokerType.TACTICIANS_SATIRE
	j.tier = JokerData.JokerTier.BUFF
	j.jp_cost = 2
	j.display_name = "Tactician's Satire"
	j.description = "Reveal target skor stage berikutnya sebelum waktunya."
	return j

static func create_late_arrival() -> JokerData:
	var j = JokerData.new()
	j.joker_type = JokerData.JokerType.THE_LATE_ARRIVAL
	j.tier = JokerData.JokerTier.BUFF
	j.jp_cost = 1
	j.display_name = "The Late Arrival"
	j.description = "Skip satu hand tanpa penalti — 'terlambat tapi selamat'."
	return j

static func create_shadow_mentor() -> JokerData:
	var j = JokerData.new()
	j.joker_type = JokerData.JokerType.SHADOW_MENTOR
	j.tier = JokerData.JokerTier.BUFF
	j.jp_cost = 3
	j.display_name = "Shadow Mentor"
	j.description = "Lihat 3 kartu teratas deck sebelum ambil hand."
	return j

static func create_vain_preservation() -> JokerData:
	var j = JokerData.new()
	j.joker_type = JokerData.JokerType.VAIN_PRESERVATION
	j.tier = JokerData.JokerTier.DEBUFF
	j.jp_cost = 2
	j.display_name = "Vain Preservation"
	j.description = "Selamatkan satu NPC di luar combat — tapi corruption naik diam-diam."
	return j

static func create_none() -> JokerData:
	var j = JokerData.new()
	j.joker_type = JokerData.JokerType.NONE
	j.tier = JokerData.JokerTier.NEUTRAL
	j.jp_cost = 0
	j.display_name = "None"
	j.description = "???"  # Tetap hidden bahkan setelah revealed — ironi disengaja
	return j

static func create_by_type(type: JokerData.JokerType) -> JokerData:
	match type:
		JokerData.JokerType.THE_INVISIBLE_SEMUT: return create_invisible_semut()
		JokerData.JokerType.HIDDEN_SINEW:        return create_hidden_sinew()
		JokerData.JokerType.TACTICIANS_SATIRE:   return create_tacticians_satire()
		JokerData.JokerType.THE_LATE_ARRIVAL:    return create_late_arrival()
		JokerData.JokerType.NIGHTLY_PROWESS:     return create_nightly_prowess()
		JokerData.JokerType.SHADOW_MENTOR:       return create_shadow_mentor()
		JokerData.JokerType.THE_OILY_TORCH:      return create_oily_torch()
		JokerData.JokerType.VAIN_PRESERVATION:   return create_vain_preservation()
		JokerData.JokerType.NONE:                return create_none()
		_: return null
