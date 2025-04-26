extends Node

var music = preload("res://Assets/Music/game_music.mp3")

var audio_player: AudioStreamPlayer

func _ready():
	audio_player = AudioStreamPlayer.new()
	audio_player.bus = "Music"  # To control volume separately
	audio_player.volume_db = -32.0
	add_child(audio_player)
	music.loop = true  # looping the music

func play_music():
	if audio_player.stream != music:
		audio_player.stream = music
		audio_player.play()

func stop_music():
	audio_player.stop()
