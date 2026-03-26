## GameManager.gd — Central state machine for the entire game.
## Tracks run progress, chips, scores, and drives scene transitions.
extends Node

# ─── Signals ─────────────────────────────────────────────────────────────────
signal state_changed(new_state: GameState)
signal round_started(info: Dictionary)
signal round_won
signal spin_resolved(winning_number: int, winnings: int, score_gained: int)
signal chips_changed(new_amount: int)
signal score_changed(new_score: int, target: int)
signal run_ended(won: bool)
signal boss_rule_active(rule: Dictionary)

# ─── State Machine ────────────────────────────────────────────────────────────
enum GameState {
	MAIN_MENU,
	BETTING,
	SPINNING,
	SHOWING_RESULT,
	ROUND_WIN,
	SHOP,
	FLOOR_TRANSITION,
	GAME_OVER,
	WIN,
}

# ─── Run Constants ────────────────────────────────────────────────────────────
const STARTING_CHIPS   := 150
const SPINS_PER_ROUND  := 5
const TOTAL_FLOORS     := 5
const ROUNDS_PER_FLOOR := 3

# Base score targets per round/floor — scaled by floor progression.
const BASE_TARGETS: Array[int] = [400, 700, 1100]  # round 1, 2, 3 (boss)

# ─── Run State ────────────────────────────────────────────────────────────────
var state: GameState = GameState.MAIN_MENU
var floor_num: int    = 1
var round_num: int    = 1
var chips: int        = STARTING_CHIPS
var score: int        = 0
var target: int       = 0
var spins_left: int   = SPINS_PER_ROUND

# Bets placed this spin: Array of { type: BetType, data: {}, amount: int }
var current_bets: Array[Dictionary] = []
var total_wagered: int = 0

# Active boss rule for this round (empty if not a boss round)
var active_boss_rule: Dictionary = {}

# Persistent run stats
var run_stats: Dictionary = {}

# Floors data cache
var _floors_data: Array[Dictionary] = []

# Zero-landing stack bonus (from haunted_zero mod)
var zero_stack_bonus: int = 0

func _ready() -> void:
	_load_floors_data()

func _load_floors_data() -> void:
	var file = FileAccess.open("res://data/floors.json", FileAccess.READ)
	if not file:
		push_error("GameManager: cannot open floors.json")
		return
	var json = JSON.new()
	if json.parse(file.get_as_text()) == OK:
		_floors_data = json.get_data()
	file.close()

# ─── Run Management ───────────────────────────────────────────────────────────

func start_new_run() -> void:
	floor_num    = 1
	round_num    = 1
	chips        = STARTING_CHIPS + ModManager.get_starting_chips_bonus()
	run_stats    = { "total_spins": 0, "biggest_win": 0, "floors_cleared": 0 }
	zero_stack_bonus = 0
	ModManager.clear_mods()
	_begin_round()

func _begin_round() -> void:
	score        = 0
	spins_left   = SPINS_PER_ROUND + ModManager.get_extra_spins()
	current_bets = []
	total_wagered = 0
	active_boss_rule = {}

	target = _calculate_target()

	var is_boss := (round_num == ROUNDS_PER_FLOOR)
	if is_boss:
		active_boss_rule = _get_boss_rule(floor_num)
		boss_rule_active.emit(active_boss_rule)

	_set_state(GameState.BETTING)
	round_started.emit({
		"floor":      floor_num,
		"round":      round_num,
		"target":     target,
		"spins":      spins_left,
		"is_boss":    is_boss,
		"boss_rule":  active_boss_rule,
		"floor_name": _get_floor_name(floor_num),
	})

func _calculate_target() -> int:
	var base       = BASE_TARGETS[round_num - 1]
	var floor_mult = pow(1.55, floor_num - 1)
	return int(base * floor_mult)

func _get_floor_name(f: int) -> String:
	for fd in _floors_data:
		if fd.get("id", 0) == f:
			return fd.get("name", "Floor %d" % f)
	return "Floor %d" % f

func _get_boss_rule(f: int) -> Dictionary:
	for fd in _floors_data:
		if fd.get("id", 0) == f:
			return fd.get("boss_rule", {})
	return {}

func get_floor_data(f: int) -> Dictionary:
	for fd in _floors_data:
		if fd.get("id", 0) == f:
			return fd
	return {}

# ─── Betting ──────────────────────────────────────────────────────────────────

func can_place_bet(amount: int) -> bool:
	return state == GameState.BETTING and chips >= amount and amount > 0

## Place or add to a bet. Returns true on success.
func place_bet(bet_type: int, bet_data: Dictionary, amount: int) -> bool:
	if not can_place_bet(amount):
		return false

	# Boss rule: straight-up bets disabled
	if active_boss_rule.get("id", "") == "outside_only" and bet_type == Constants.BetType.STRAIGHT:
		return false

	for bet in current_bets:
		if bet.type == bet_type and bet.data == bet_data:
			bet.amount += amount
			_spend_chips(amount)
			total_wagered += amount
			return true

	current_bets.append({ "type": bet_type, "data": bet_data.duplicate(), "amount": amount })
	_spend_chips(amount)
	total_wagered += amount
	return true

func remove_bet(bet_type: int, bet_data: Dictionary) -> void:
	for i in range(current_bets.size() - 1, -1, -1):
		var b = current_bets[i]
		if b.type == bet_type and b.data == bet_data:
			_add_chips(b.amount)
			total_wagered -= b.amount
			current_bets.remove_at(i)
			return

func clear_all_bets() -> void:
	for b in current_bets:
		_add_chips(b.amount)
		total_wagered -= b.amount
	current_bets.clear()

func get_bet_amount_on(bet_type: int, bet_data: Dictionary) -> int:
	for b in current_bets:
		if b.type == bet_type and b.data == bet_data:
			return b.amount
	return 0

func get_total_bet() -> int:
	var total := 0
	for b in current_bets:
		total += b.amount
	return total

# ─── Spin Execution ───────────────────────────────────────────────────────────

## Called by the wheel when animation completes. Resolves all bets.
func resolve_spin(winning_number: int) -> void:
	if state != GameState.SPINNING:
		return

	spins_left -= 1
	run_stats["total_spins"] = run_stats.get("total_spins", 0) + 1

	# Base winnings
	var winnings := _calculate_winnings(winning_number)

	# Mod: haunted_zero — track zero stack
	if winning_number == 0:
		var stack_bonus = ModManager.get_zero_stack_bonus()
		zero_stack_bonus += stack_bonus

	# Mod: prevent bust — trigger once if would go bust
	if winnings == 0 and chips <= 0:
		var saved = ModManager.try_prevent_bust()
		if saved > 0:
			chips = saved
			chips_changed.emit(chips)

	# Apply mod effects to winnings
	winnings = ModManager.apply_win_modifiers(winning_number, winnings, current_bets, total_wagered)
	winnings += zero_stack_bonus if winning_number != 0 else 0

	# Boss rule: rising_tide — target escalates each spin
	if active_boss_rule.get("id", "") == "rising_tide":
		target += 200

	# Boss rule: devils_deal — extra chip cost on loss, double on win
	if active_boss_rule.get("id", "") == "devils_deal":
		if winnings == 0:
			chips = max(0, chips - 20)
			chips_changed.emit(chips)
		elif winnings > 0:
			winnings *= 2

	# Score gained = net winnings (winnings already include stake return)
	var score_gained := winnings
	score_gained = ModManager.apply_score_modifiers(score_gained, winning_number, current_bets)

	if winnings > 0:
		_add_chips(winnings)
		if winnings > run_stats.get("biggest_win", 0):
			run_stats["biggest_win"] = winnings

	score += score_gained
	score_changed.emit(score, target)

	current_bets.clear()
	total_wagered = 0

	_set_state(GameState.SHOWING_RESULT)
	spin_resolved.emit(winning_number, winnings, score_gained)

## Trigger the spin — moves state from BETTING → SPINNING.
func start_spin() -> void:
	if state != GameState.BETTING or current_bets.is_empty():
		return
	_set_state(GameState.SPINNING)

## After the result screen, continue to next spin or end round.
func continue_after_result() -> void:
	if state != GameState.SHOWING_RESULT:
		return

	if score >= target:
		_set_state(GameState.ROUND_WIN)
		round_won.emit()
		return

	if spins_left <= 0 or chips <= 0:
		game_over()
		return

	_set_state(GameState.BETTING)

# ─── Round/Floor Progression ─────────────────────────────────────────────────

func advance_from_round_win() -> void:
	if round_num < ROUNDS_PER_FLOOR:
		round_num += 1
		_set_state(GameState.SHOP)
	else:
		run_stats["floors_cleared"] = run_stats.get("floors_cleared", 0) + 1
		if floor_num < TOTAL_FLOORS:
			floor_num += 1
			round_num  = 1
			_set_state(GameState.FLOOR_TRANSITION)
		else:
			_set_state(GameState.WIN)
			run_ended.emit(true)

func leave_shop() -> void:
	# Called when player presses "Continue" in the shop
	if state == GameState.SHOP:
		chips += ModManager.get_floor_start_chips_bonus() if round_num == 1 else 0
		chips_changed.emit(chips)
		_begin_round()

func leave_floor_transition() -> void:
	if state == GameState.FLOOR_TRANSITION:
		chips += ModManager.get_floor_start_chips_bonus()
		chips_changed.emit(chips)
		_begin_round()

func game_over() -> void:
	_set_state(GameState.GAME_OVER)
	run_ended.emit(false)

# ─── Chip Helpers ─────────────────────────────────────────────────────────────

func _spend_chips(amount: int) -> void:
	chips -= amount
	chips_changed.emit(chips)

func _add_chips(amount: int) -> void:
	chips += amount
	chips_changed.emit(chips)

# ─── Winnings Calculator ──────────────────────────────────────────────────────

func _calculate_winnings(winning_number: int) -> int:
	var total_win := 0
	for bet in current_bets:
		var btype := bet.type as Constants.BetType
		if Constants.is_number_in_bet(winning_number, btype, bet.data):
			var payout := Constants.BET_PAYOUTS[btype]
			# Apply mod payout multipliers
			payout = ModManager.apply_payout_multiplier(btype, payout)
			# Boss rule: odd numbers pay half
			if active_boss_rule.get("id", "") == "odd_death":
				if winning_number != 0 and winning_number % 2 != 0:
					payout = max(0, payout / 2)
			total_win += bet.amount * (payout + 1)
	return total_win

# ─── State Helper ─────────────────────────────────────────────────────────────

func _set_state(s: GameState) -> void:
	state = s
	state_changed.emit(s)
