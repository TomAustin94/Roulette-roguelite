## ModManager.gd — Manages mod acquisition, storage, and effect application.
extends Node

signal mod_acquired(mod: Dictionary)
signal mod_triggered(mod_id: String, description: String)

var active_mods: Array[Dictionary] = []
var mod_database: Array[Dictionary] = []

# Per-run tracking for stateful mods
var _bust_prevented: bool = false
var _zero_stacks: int     = 0

func _ready() -> void:
	_load_mod_database()

func _load_mod_database() -> void:
	var file = FileAccess.open("res://data/mods.json", FileAccess.READ)
	if not file:
		push_error("ModManager: cannot open mods.json")
		return
	var json = JSON.new()
	if json.parse(file.get_as_text()) == OK:
		mod_database = json.get_data()
	file.close()

# ─── Mod Management ───────────────────────────────────────────────────────────

func clear_mods() -> void:
	active_mods.clear()
	_bust_prevented = false
	_zero_stacks    = 0

func add_mod_by_id(mod_id: String) -> bool:
	for mod in mod_database:
		if mod.get("id", "") == mod_id:
			# Unique mods can only be held once
			if mod.get("unique", false):
				for owned in active_mods:
					if owned.get("id", "") == mod_id:
						return false
			active_mods.append(mod.duplicate(true))
			mod_acquired.emit(mod)
			return true
	return false

func has_mod(mod_id: String) -> bool:
	for m in active_mods:
		if m.get("id", "") == mod_id:
			return true
	return false

## Returns `count` random purchasable mods for the shop.
func get_shop_offer(count: int = 3) -> Array[Dictionary]:
	var owned_unique_ids: Array[String] = []
	for m in active_mods:
		if m.get("unique", false):
			owned_unique_ids.append(m.get("id", ""))

	var available: Array[Dictionary] = []
	for mod in mod_database:
		if mod.get("unique", false) and mod.get("id", "") in owned_unique_ids:
			continue
		available.append(mod)

	available.shuffle()
	var offer: Array[Dictionary] = []
	for i in min(count, available.size()):
		offer.append(available[i])
	return offer

# ─── Starting Bonuses ─────────────────────────────────────────────────────────

func get_starting_chips_bonus() -> int:
	var bonus := 0
	for m in active_mods:
		if m.get("trigger", "") == "on_run_start":
			bonus += m.get("chips_bonus", 0)
	return bonus

func get_extra_spins() -> int:
	var extra := 0
	for m in active_mods:
		extra += m.get("extra_spins", 0)
	return extra

func get_floor_start_chips_bonus() -> int:
	var bonus := 0
	for m in active_mods:
		if m.get("trigger", "") == "on_floor_start":
			bonus += m.get("chips_bonus", 0)
	return bonus

func get_zero_stack_bonus() -> int:
	var bonus := 0
	for m in active_mods:
		if m.get("trigger", "") == "zero_stacks":
			bonus += m.get("stack_bonus", 0)
	return bonus

# ─── Win Modifiers ────────────────────────────────────────────────────────────

## Apply all modifier effects that affect raw winnings.
func apply_win_modifiers(
	winning_number: int,
	winnings: int,
	bets: Array[Dictionary],
	total_wagered: int
) -> int:
	var result := winnings

	for m in active_mods:
		var trigger: String = m.get("trigger", "")
		match trigger:
			"on_zero":
				if winning_number == 0 and winnings > 0:
					result = int(result * m.get("multiplier", 1.0))
					mod_triggered.emit(m.get("id",""), "Devil's Luck triggered!")

			"bonus_on_red":
				if winning_number in Constants.RED_NUMBERS and winnings > 0:
					result += m.get("bonus", 0)
					mod_triggered.emit(m.get("id",""), "+%d from Red Blessing" % m.get("bonus", 0))

			"bonus_on_black":
				if winning_number in Constants.BLACK_NUMBERS and winnings > 0:
					result += m.get("bonus", 0)
					mod_triggered.emit(m.get("id",""), "+%d from Black Market" % m.get("bonus", 0))

			"on_loss":
				if winnings == 0 and total_wagered > 0:
					var refund := int(total_wagered * m.get("refund_rate", 0.0))
					result += refund
					if refund > 0:
						mod_triggered.emit(m.get("id",""), "Grim Refund: +%d" % refund)

			"on_big_win":
				if winnings >= m.get("threshold", 999999):
					result = int(result * m.get("multiplier", 1.0))
					mod_triggered.emit(m.get("id",""), "High Roller bonus!")

			"mirror_even_odd":
				# If player won on Even, also pay out as if they bet Odd with same stake
				for bet in bets:
					if bet.type == Constants.BetType.EVEN and Constants.is_number_in_bet(winning_number, bet.type, bet.data):
						# odd is 1:1 — return the same as an even bet win
						result += bet.amount * 2
						mod_triggered.emit(m.get("id",""), "Mirror Bet: bonus Even→Odd!")
						break

	return result

## Apply modifiers that affect how much the score target increases.
func apply_score_modifiers(
	score_gained: int,
	winning_number: int,
	bets: Array[Dictionary]
) -> int:
	var result := score_gained

	for m in active_mods:
		var strigger: String = m.get("score_trigger", "")
		match strigger:
			"straight_up_win":
				for bet in bets:
					if bet.type == Constants.BetType.STRAIGHT \
					and Constants.is_number_in_bet(winning_number, bet.type, bet.data):
						result = int(result * m.get("score_multiplier", 1.0))
						mod_triggered.emit(m.get("id",""), "Straight Razor: score ×%.1f!" % m.get("score_multiplier", 1.0))
						break
			"always":
				result = int(result * m.get("score_multiplier", 1.0))
				mod_triggered.emit(m.get("id",""), "The Grind: score ×%.1f!" % m.get("score_multiplier", 1.0))

	return result

## Modify a bet-type's base payout multiplier.
func apply_payout_multiplier(bet_type: Constants.BetType, base_payout: int) -> int:
	var mult := 1.0
	for m in active_mods:
		if m.get("buff_bet_type", -1) == int(bet_type):
			mult *= m.get("payout_mult", 1.0)
	return int(base_payout * mult)

## If soul_chip mod is owned and bust hasn't been prevented yet, return saved chips.
func try_prevent_bust() -> int:
	if _bust_prevented:
		return 0
	for m in active_mods:
		if m.get("trigger", "") == "prevent_bust":
			_bust_prevented = true
			mod_triggered.emit(m.get("id",""), "Soul Chip saved you!")
			return m.get("bust_chips", 10)
	return 0
