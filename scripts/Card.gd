class_name Card
extends Resource

enum Suit { HEARTS, DIAMONDS, CLUBS, SPADES }
enum Rank { TWO=2, THREE, FOUR, FIVE, SIX, SEVEN, 
			EIGHT, NINE, TEN, JACK, QUEEN, KING, ACE }

@export var suit: Suit = Suit.HEARTS
@export var rank: Rank = Rank.TWO

func get_chip_value() -> int:
	match rank:
		Rank.ACE: return 11
		Rank.KING, Rank.QUEEN, Rank.JACK: return 10
		_: return rank

func get_display_name() -> String:
	var rank_names = {
		2:"2", 3:"3", 4:"4", 5:"5", 6:"6", 7:"7",
		8:"8", 9:"9", 10:"10", 11:"J", 12:"Q", 13:"K", 14:"A"
	}
	var suit_names = {
		Suit.HEARTS:"♥", Suit.DIAMONDS:"♦",
		Suit.CLUBS:"♣", Suit.SPADES:"♠"
	}
	return rank_names[rank] + suit_names[suit]
