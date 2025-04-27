extends Node

var beaten_levels:Array[bool]=[false,false,false,false,false,false]

func reset_progress():
	var save = FileAccess.open("user://progress.save", FileAccess.WRITE)
	save.store_var([false,false,false,false,false,false])

func save_progress():
	var save = FileAccess.open("user://progress.save", FileAccess.WRITE)
	save.store_var(beaten_levels)

func load_progress():
	if FileAccess.file_exists("user://progress.save"):
		var save = FileAccess.open("user://progress.save", FileAccess.READ)
		var levels =save.get_var()
		if levels != null:
			beaten_levels = levels
