extends Node

const SAVE_PATH := "user://game.save"
const DREAMLO := "ENTER DREAMLO URL HERE"

onready var http_request = $HTTPRequest

enum {
	DF_EASY = 0,
	DF_NORMAL = 1,
	DF_HARD = 2
}

#Best score for each difficulty
var score_best := [0,0,0,0]

#What's our in game difficulty?
var difficulty := DF_NORMAL

#What is this player called on the leaderboard?
var leaderboard_name := ""

#Load in scores
func _ready() -> void:
	#Load scores
	load_scores()
	#Randomize
	randomize()

func current_best() -> int:
	return score_best[difficulty]

func update_best(score:int) -> void:
	score_best[difficulty] = max(score_best[difficulty],score)
	save_scores()

#Used to save scores on quit
func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		save_scores()
		get_tree().quit() # default behavior

#Save game scores
func save_scores() -> void:
	var save_game = File.new()
	#Open file
	save_game.open(SAVE_PATH,File.WRITE)
	#Loop over scores
	save_game.store_line(to_json(score_best))
	save_game.store_line(leaderboard_name)
	save_game.close()
	#Try and send score to leaderboard
	if leaderboard_name != "":
		http_request.request(Marshalls.base64_to_utf8(DREAMLO) + "/add/"+leaderboard_name+"/"+str(score_best[difficulty]))

#Load game scores
func load_scores() -> void:
	var save_game = File.new()
	if not save_game.file_exists(SAVE_PATH):
		return
	#Load file
	save_game.open(SAVE_PATH,File.READ)
	#Reset existing scores
	score_best = parse_json(save_game.get_line())
	leaderboard_name = save_game.get_line()
	save_game.close()
