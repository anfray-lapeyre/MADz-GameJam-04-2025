extends Node

var highest_unlocked_level: int = 1

func reset_progress():
	var save = FileAccess.open("user://progress.save", FileAccess.WRITE)
	save.store_32(1)

func save_progress():
	var save = FileAccess.open("user://progress.save", FileAccess.WRITE)
	save.store_32(highest_unlocked_level)

func load_progress():
	if FileAccess.file_exists("user://progress.save"):
		var save = FileAccess.open("user://progress.save", FileAccess.READ)
		highest_unlocked_level = save.get_32()
