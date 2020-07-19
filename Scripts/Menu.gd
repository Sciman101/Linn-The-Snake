extends CanvasLayer

const GAME_SCENE := "res://Game.tscn"
const MENU_STRING := "%s %s %s\nBest: %d\n\nPress Space to Start"
const DIFFICULTY_STRINGS := ["Easy","Normal","Canon"]

const OFFSET = Vector2(64,64)

onready var label = $Label
onready var sfx = $SelectSFX
onready var bg = $Background

var selected_difficulty : int = 1

func _ready() -> void:
	set_process_input(true)
	update_label()

#Scroll the background
func _process(delta:float) -> void:
	bg.rect_position -= OFFSET * delta
	if bg.rect_position <= -OFFSET:
		bg.rect_position += OFFSET

#Handle input
func _input(event) -> void:
	if event.is_action_pressed("right"):
		selected_difficulty = min(selected_difficulty+1,2)
		update_label()
	elif event.is_action_pressed("left"):
		selected_difficulty = max(selected_difficulty-1,0)
		update_label()
	elif event.is_action_pressed("accept"):
		start_game()

func start_game() -> void:
	Global.difficulty = selected_difficulty
	set_process_input(false)
	Transition.transition_to(GAME_SCENE)

func update_label() -> void:
	var difficulties = DIFFICULTY_STRINGS.duplicate()
	for i in range(difficulties.size()):
		if i == selected_difficulty:
			difficulties[i] = "["+difficulties[i]+"]"
	difficulties.append(Global.score_best[selected_difficulty])
	label.text = MENU_STRING % difficulties
	sfx.play()
