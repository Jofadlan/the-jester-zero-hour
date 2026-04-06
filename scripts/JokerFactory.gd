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
