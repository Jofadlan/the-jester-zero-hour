class_name JPManager
extends Node

signal jp_changed(current: int, maximum: int)

var jp_current: int = 10
var jp_max: int = 10

const BASE_JP = 10
const JP_PER_JOKER_SLOT = 4
const DISCARD_COST = 1

func reset_for_duel(joker_count: int = 0):
	jp_max = BASE_JP + (joker_count * JP_PER_JOKER_SLOT)
	jp_current = jp_max
	emit_signal("jp_changed", jp_current, jp_max)

func can_discard(amount: int = 1) -> bool:
	return jp_current >= (amount * DISCARD_COST)

func spend_discard(amount: int = 1) -> bool:
	if not can_discard(amount):
		return false
	jp_current -= amount * DISCARD_COST
	emit_signal("jp_changed", jp_current, jp_max)
	return true

func can_use_joker(cost: int) -> bool:
	return jp_current >= cost

func spend_joker(cost: int) -> bool:
	if not can_use_joker(cost):
		return false
	jp_current -= cost
	emit_signal("jp_changed", jp_current, jp_max)
	return true

func is_empty() -> bool:
	return jp_current <= 0
