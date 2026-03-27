## SaveManager.gd — Persist run state between sessions.
## Saves at "Save & Quit" so the player can resume exactly where they left off.
extends Node

const SAVE_PATH := "user://save.cfg"

# ─── Public API ───────────────────────────────────────────────────────────────

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

## Persist the current run to disk. Saves at round boundary (beginning of round).
func save_run() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("run", "floor_num",  GameManager.floor_num)
	cfg.set_value("run", "round_num",  GameManager.round_num)
	cfg.set_value("run", "chips",      GameManager.chips)
	cfg.set_value("run", "run_stats",  GameManager.run_stats)
	cfg.set_value("run", "total_score", GameManager.total_score)
	cfg.save(SAVE_PATH)

## Restore a saved run into GameManager. Returns true on success.
func load_run() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return false
	GameManager.floor_num   = cfg.get_value("run", "floor_num",  1)
	GameManager.round_num   = cfg.get_value("run", "round_num",  1)
	GameManager.chips       = cfg.get_value("run", "chips",      GameManager.STARTING_CHIPS)
	GameManager.run_stats   = cfg.get_value("run", "run_stats",  {})
	GameManager.total_score = cfg.get_value("run", "total_score", 0)
	return true

## Erase a saved run from disk.
func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

## Return lightweight preview info without fully loading state (for menu display).
func get_save_preview() -> Dictionary:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return {}
	return {
		"floor_num":   cfg.get_value("run", "floor_num",  1),
		"round_num":   cfg.get_value("run", "round_num",  1),
		"chips":       cfg.get_value("run", "chips",      0),
		"total_score": cfg.get_value("run", "total_score", 0),
		"run_stats":   cfg.get_value("run", "run_stats",  {}),
	}
