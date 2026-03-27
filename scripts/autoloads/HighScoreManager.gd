## HighScoreManager.gd — Persist and retrieve top-5 run scores.
extends Node

const SCORES_PATH := "user://scores.cfg"
const MAX_ENTRIES := 5

# ─── Public API ───────────────────────────────────────────────────────────────

## Returns up to MAX_ENTRIES score dictionaries, sorted best-first.
func get_scores() -> Array:
	var cfg := ConfigFile.new()
	if cfg.load(SCORES_PATH) != OK:
		return []
	var scores := []
	if not cfg.has_section("scores"):
		return []
	for key in cfg.get_section_keys("scores"):
		scores.append(cfg.get_value("scores", key))
	scores.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.get("score", 0) > b.get("score", 0)
	)
	return scores

## Record the current run result. Call this when the run ends (win or loss).
func submit_score(won: bool) -> void:
	var entry := {
		"score":          GameManager.total_score,
		"floors_cleared": GameManager.run_stats.get("floors_cleared", 0),
		"total_spins":    GameManager.run_stats.get("total_spins", 0),
		"biggest_win":    GameManager.run_stats.get("biggest_win", 0),
		"floor_num":      GameManager.floor_num,
		"round_num":      GameManager.round_num,
		"chips":          GameManager.chips,
		"won":            won,
		"date":           Time.get_date_string_from_system(),
	}

	var scores := get_scores()
	scores.append(entry)
	scores.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.get("score", 0) > b.get("score", 0)
	)
	if scores.size() > MAX_ENTRIES:
		scores.resize(MAX_ENTRIES)

	var cfg := ConfigFile.new()
	cfg.load(SCORES_PATH)   # load existing so we don't overwrite other sections
	for i in scores.size():
		cfg.set_value("scores", "entry_%d" % i, scores[i])
	cfg.save(SCORES_PATH)

## Returns true if the given score beats the current #1.
func is_new_best(score: int) -> bool:
	var scores := get_scores()
	if scores.is_empty():
		return true
	return score > scores[0].get("score", 0)
