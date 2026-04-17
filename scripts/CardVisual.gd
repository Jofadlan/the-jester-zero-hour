class_name CardVisual
extends RefCounted

const CARD_WIDTH  = 64
const CARD_HEIGHT = 64
const SHEET_COLS  = 14

# Suit → baris di spritesheet
const SUIT_ROW = {
	Card.Suit.HEARTS:   0,
	Card.Suit.DIAMONDS: 1,
	Card.Suit.CLUBS:    2,
	Card.Suit.SPADES:   3,
}

# Rank → kolom di spritesheet (A=0, 2=1, ..., K=12)
const RANK_COL = {
	Card.Rank.ACE:   0,
	Card.Rank.TWO:   1,
	Card.Rank.THREE: 2,
	Card.Rank.FOUR:  3,
	Card.Rank.FIVE:  4,
	Card.Rank.SIX:   5,
	Card.Rank.SEVEN: 6,
	Card.Rank.EIGHT: 7,
	Card.Rank.NINE:  8,
	Card.Rank.TEN:   9,
	Card.Rank.JACK:  10,
	Card.Rank.QUEEN: 11,
	Card.Rank.KING:  12,
}

const COL_BACK_WHITE = 13
const COL_BACK_BLUE  = 13
const ROW_BACK_WHITE = 0
const ROW_BACK_BLUE  = 1

static func get_card_region(card: Card) -> Rect2:
	var col = RANK_COL[card.rank]
	var row = SUIT_ROW[card.suit]
	return Rect2(col * CARD_WIDTH, row * CARD_HEIGHT, CARD_WIDTH, CARD_HEIGHT)

static func get_back_region(joker_back: bool = false) -> Rect2:
	var row = ROW_BACK_BLUE if joker_back else ROW_BACK_WHITE
	return Rect2(COL_BACK_WHITE * CARD_WIDTH, row * CARD_HEIGHT, CARD_WIDTH, CARD_HEIGHT)

static func get_joker_region(variant: int = 0) -> Rect2:
	# variant 0 = baris 2, variant 1 = baris 3
	var row = 2 + variant
	return Rect2(13 * CARD_WIDTH, row * CARD_HEIGHT, CARD_WIDTH, CARD_HEIGHT)
