class_name HandEvaluator
extends RefCounted

enum HandType {
	HIGH_CARD, PAIR, TWO_PAIR, THREE_OF_A_KIND,
	STRAIGHT, FLUSH, FULL_HOUSE, FOUR_OF_A_KIND,
	STRAIGHT_FLUSH, ROYAL_FLUSH
}

# Base chips dan multiplier per hand type
const HAND_DATA = {
	HandType.HIGH_CARD:        { "chips": 5,   "mult": 1 },
	HandType.PAIR:             { "chips": 10,  "mult": 2 },
	HandType.TWO_PAIR:         { "chips": 20,  "mult": 2 },
	HandType.THREE_OF_A_KIND:  { "chips": 30,  "mult": 3 },
	HandType.STRAIGHT:         { "chips": 30,  "mult": 4 },
	HandType.FLUSH:            { "chips": 35,  "mult": 4 },
	HandType.FULL_HOUSE:       { "chips": 40,  "mult": 4 },
	HandType.FOUR_OF_A_KIND:   { "chips": 60,  "mult": 7 },
	HandType.STRAIGHT_FLUSH:   { "chips": 100, "mult": 8 },
	HandType.ROYAL_FLUSH:      { "chips": 100, "mult": 8 },
}

func evaluate(played_cards: Array[Card]) -> Dictionary:
	var hand_type = _detect_hand(played_cards)
	var base = HAND_DATA[hand_type]
	
	# Ambil hanya kartu yang berkontribusi ke hand
	var scoring_cards = _get_scoring_cards(played_cards, hand_type)
	
	var card_chips = 0
	for card in scoring_cards:
		card_chips += card.get_chip_value()
	
	var total = (base["chips"] + card_chips) * base["mult"]
	return {
		"hand_type": hand_type,
		"chips": base["chips"] + card_chips,
		"mult": base["mult"],
		"score": total
	}

func _get_scoring_cards(cards: Array[Card], hand_type: HandType) -> Array[Card]:
	var rank_counts = _count_ranks(cards.map(func(c): return c.rank))
	var result: Array[Card] = []
	
	match hand_type:
		HandType.ROYAL_FLUSH, HandType.STRAIGHT_FLUSH, \
		HandType.FLUSH, HandType.STRAIGHT:
			# Semua kartu berkontribusi
			result = cards.duplicate()
		
		HandType.FOUR_OF_A_KIND:
			# Hanya 4 kartu yang sama ranknya
			for card in cards:
				if rank_counts[card.rank] == 4:
					result.append(card)
		
		HandType.FULL_HOUSE:
			# Semua 5 kartu (3+2) berkontribusi
			result = cards.duplicate()
		
		HandType.THREE_OF_A_KIND:
			# Hanya 3 kartu yang sama ranknya
			for card in cards:
				if rank_counts[card.rank] == 3:
					result.append(card)
		
		HandType.TWO_PAIR:
			# Hanya 4 kartu (dua pasang)
			for card in cards:
				if rank_counts[card.rank] == 2:
					result.append(card)
		
		HandType.PAIR:
			# Hanya 2 kartu yang sama ranknya
			for card in cards:
				if rank_counts[card.rank] == 2:
					result.append(card)
		
		HandType.HIGH_CARD:
			# Hanya kartu dengan nilai tertinggi
			var highest_rank = 0
			for card in cards:
				if card.rank > highest_rank:
					highest_rank = card.rank
			for card in cards:
				if card.rank == highest_rank:
					result.append(card)
					break
	
	return result

func _detect_hand(cards: Array[Card]) -> HandType:
	if cards.size() < 1:
		return HandType.HIGH_CARD
	
	var ranks = []
	var suits = []
	for card in cards:
		ranks.append(card.rank)
		suits.append(card.suit)
	
	ranks.sort()
	
	var is_flush = suits.size() == 5 and suits.count(suits[0]) == 5
	var is_straight = _check_straight(ranks)
	var rank_counts = _count_ranks(ranks)
	var counts = rank_counts.values()
	counts.sort()
	counts.reverse()
	
	# Pastikan counts punya minimal 2 element sebelum akses index [1]
	while counts.size() < 2:
		counts.append(0)
	
	if is_straight and is_flush:
		if ranks[-1] == Card.Rank.ACE and ranks[0] == Card.Rank.TEN:
			return HandType.ROYAL_FLUSH
		return HandType.STRAIGHT_FLUSH
	if counts[0] == 4: return HandType.FOUR_OF_A_KIND
	if counts[0] == 3 and counts[1] == 2: return HandType.FULL_HOUSE
	if is_flush: return HandType.FLUSH
	if is_straight: return HandType.STRAIGHT
	if counts[0] == 3: return HandType.THREE_OF_A_KIND
	if counts[0] == 2 and counts[1] == 2: return HandType.TWO_PAIR
	if counts[0] == 2: return HandType.PAIR
	return HandType.HIGH_CARD
func _check_straight(sorted_ranks: Array) -> bool:
	if sorted_ranks.size() != 5:
		return false
	for i in range(1, sorted_ranks.size()):
		if sorted_ranks[i] - sorted_ranks[i-1] != 1:
			return false
	return true

func _count_ranks(ranks: Array) -> Dictionary:
	var counts = {}
	for r in ranks:
		counts[r] = counts.get(r, 0) + 1
	return counts
