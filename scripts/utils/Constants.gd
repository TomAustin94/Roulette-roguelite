## Constants.gd — Global constants and helpers for the roulette game.
## Loaded as an autoload so all scripts can access it directly.
extends Node

# ─── Wheel Layout ────────────────────────────────────────────────────────────
# European roulette: 37 numbers (0–36), ordered as they appear clockwise.
const WHEEL_NUMBERS: Array[int] = [
	0, 32, 15, 19, 4, 21, 2, 25, 17, 34, 6, 27, 13, 36, 11, 30,
	8, 23, 10, 5, 24, 16, 33, 1, 20, 14, 31, 9, 22, 18, 29, 7,
	28, 12, 35, 3, 26
]

const RED_NUMBERS: Array[int] = [
	1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36
]

const BLACK_NUMBERS: Array[int] = [
	2, 4, 6, 8, 10, 11, 13, 15, 17, 20, 22, 24, 26, 28, 29, 31, 33, 35
]

# ─── Bet Types ────────────────────────────────────────────────────────────────
enum BetType {
	STRAIGHT,   # Single number — pays 35:1
	RED,        # All red numbers — pays 1:1
	BLACK,      # All black numbers — pays 1:1
	ODD,        # All odd numbers — pays 1:1
	EVEN,       # All even numbers — pays 1:1
	LOW,        # 1–18 — pays 1:1
	HIGH,       # 19–36 — pays 1:1
	DOZEN_1,    # 1–12 — pays 2:1
	DOZEN_2,    # 13–24 — pays 2:1
	DOZEN_3,    # 25–36 — pays 2:1
	COLUMN_1,   # 1,4,7,… — pays 2:1
	COLUMN_2,   # 2,5,8,… — pays 2:1
	COLUMN_3,   # 3,6,9,… — pays 2:1
}

# Base payout multipliers (return = bet * (payout + 1) to include stake)
const BET_PAYOUTS: Dictionary = {
	BetType.STRAIGHT:  35,
	BetType.RED:        1,
	BetType.BLACK:      1,
	BetType.ODD:        1,
	BetType.EVEN:       1,
	BetType.LOW:        1,
	BetType.HIGH:       1,
	BetType.DOZEN_1:    2,
	BetType.DOZEN_2:    2,
	BetType.DOZEN_3:    2,
	BetType.COLUMN_1:   2,
	BetType.COLUMN_2:   2,
	BetType.COLUMN_3:   2,
}

# Bet type display names
const BET_NAMES: Dictionary = {
	BetType.STRAIGHT:  "Straight Up",
	BetType.RED:       "Red",
	BetType.BLACK:     "Black",
	BetType.ODD:       "Odd",
	BetType.EVEN:      "Even",
	BetType.LOW:       "1–18",
	BetType.HIGH:      "19–36",
	BetType.DOZEN_1:   "1st 12",
	BetType.DOZEN_2:   "2nd 12",
	BetType.DOZEN_3:   "3rd 12",
	BetType.COLUMN_1:  "Column 1",
	BetType.COLUMN_2:  "Column 2",
	BetType.COLUMN_3:  "Column 3",
}

# ─── Palette ──────────────────────────────────────────────────────────────────
const COLOR_RED       := Color(0.75, 0.08, 0.08)
const COLOR_BLACK     := Color(0.10, 0.10, 0.10)
const COLOR_GREEN     := Color(0.06, 0.45, 0.12)
const COLOR_GOLD      := Color(0.90, 0.75, 0.20)
const COLOR_BG        := Color(0.05, 0.07, 0.05)
const COLOR_FELT      := Color(0.04, 0.28, 0.10)
const COLOR_FELT_DARK := Color(0.03, 0.20, 0.07)
const COLOR_TEXT      := Color(0.95, 0.92, 0.85)
const COLOR_HIGHLIGHT := Color(1.00, 0.92, 0.40)

# ─── Chip Values ─────────────────────────────────────────────────────────────
const CHIP_VALUES: Array[int] = [5, 10, 25, 50, 100]
const CHIP_COLORS: Array[Color] = [
	Color(0.9, 0.9, 0.9),   # 5   — white
	Color(0.2, 0.5, 0.9),   # 10  — blue
	Color(0.2, 0.7, 0.3),   # 25  — green
	Color(0.9, 0.6, 0.1),   # 50  — orange
	Color(0.8, 0.1, 0.1),   # 100 — red
]

# ─── Helpers ──────────────────────────────────────────────────────────────────
static func get_number_color(num: int) -> String:
	if num == 0:
		return "green"
	if num in RED_NUMBERS:
		return "red"
	return "black"

## Returns true if `number` falls within the given bet.
static func is_number_in_bet(number: int, bet_type: BetType, bet_data: Dictionary) -> bool:
	match bet_type:
		BetType.STRAIGHT:
			return number == bet_data.get("number", -1)
		BetType.RED:
			return number in RED_NUMBERS
		BetType.BLACK:
			return number in BLACK_NUMBERS
		BetType.ODD:
			return number != 0 and number % 2 != 0
		BetType.EVEN:
			return number != 0 and number % 2 == 0
		BetType.LOW:
			return number >= 1 and number <= 18
		BetType.HIGH:
			return number >= 19 and number <= 36
		BetType.DOZEN_1:
			return number >= 1 and number <= 12
		BetType.DOZEN_2:
			return number >= 13 and number <= 24
		BetType.DOZEN_3:
			return number >= 25 and number <= 36
		BetType.COLUMN_1:
			return number != 0 and (number - 1) % 3 == 0
		BetType.COLUMN_2:
			return number != 0 and (number - 2) % 3 == 0
		BetType.COLUMN_3:
			return number != 0 and number % 3 == 0
	return false

## Returns the chip color for a given chip value index.
static func get_chip_color(value: int) -> Color:
	var idx = CHIP_VALUES.find(value)
	if idx >= 0:
		return CHIP_COLORS[idx]
	return Color.WHITE
