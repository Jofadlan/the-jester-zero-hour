class_name DeckManager
extends Node

var full_deck: Array[Card] = []
var draw_pile: Array[Card] = []
var hand: Array[Card] = []
var discard_pile: Array[Card] = []

const HAND_SIZE = 7
const MAX_PLAY = 5

func _ready():
	build_deck()
	shuffle_deck()

func build_deck():
	full_deck.clear()
	for suit in Card.Suit.values():
		for rank in Card.Rank.values():
			var card = Card.new()
			card.suit = suit
			card.rank = rank
			full_deck.append(card)

func shuffle_deck():
	draw_pile = full_deck.duplicate()
	draw_pile.shuffle()

func deal_hand():
	hand.clear()
	for i in HAND_SIZE:
		if draw_pile.is_empty():
			refill_from_discard()
		if not draw_pile.is_empty():
			hand.append(draw_pile.pop_back())

func discard_cards(cards_to_discard: Array[Card]):
	for card in cards_to_discard:
		if card in hand:
			hand.erase(card)
			discard_pile.append(card)

func refill_from_discard():
	draw_pile = discard_pile.duplicate()
	draw_pile.shuffle()
	discard_pile.clear()
