extends CanvasLayer

const GET_JSON = "/json"
const NAME_INPUT_TEMPLATE = "Enter name for leaderboard\n\n%s_"
const INVALID_NAME_CHARS = "*/\\"

# What should we expect upon receiving data?
enum {
	LEADERBOARD
}

onready var http_request = $HTTPRequest
onready var label = $"Background/LeaderboardDisplay/Leaderboard"

onready var leaderboard_display = $Background/LeaderboardDisplay
onready var name_input = $Background/NameInputLabel

var dreamlo_url : String

var expected_data : int
var getting_name : bool = false
var user_name : String = ""

func _ready() -> void:
	set_process_unhandled_input(true)
	#Get the leaderboard data
	dreamlo_url = Marshalls.base64_to_utf8(Global.DREAMLO)
	
	#What do we do?
	if Global.leaderboard_name == "":
		
		#We need to get the name!
		getting_name = true
		leaderboard_display.visible = false
		name_input.visible = true
		
	else:
		request_leaderboard_data()

func request_leaderboard_data() -> void:
	#Send HTTP request
	http_request.request(dreamlo_url+GET_JSON)
	expected_data = LEADERBOARD

#Handle input
func _unhandled_input(event) -> void:
	if not getting_name:
		if event.is_action_pressed("accept"):
			Transition.transition_to("res://Menu.tscn")
			get_tree().set_input_as_handled()
	else:
		#Get name!
		if event is InputEventKey and event.is_pressed():
			if event.scancode == KEY_BACKSPACE:
				#Backspace
				user_name = user_name.substr(0,user_name.length()-1)
				update_name_display()
			elif event.scancode == KEY_ENTER:
				#Submit
				Global.leaderboard_name = user_name
				#Force game to send leaderboard data
				Global.update_best(-1)
				
				leaderboard_display.visible = true
				name_input.visible = false
				
				getting_name = false
				request_leaderboard_data()
			else:
				#Type normally
				var c = char(event.unicode)
				if not c in INVALID_NAME_CHARS:
					user_name += c
					update_name_display()
		get_tree().set_input_as_handled()

func update_name_display() -> void:
	name_input.text = NAME_INPUT_TEMPLATE % user_name

func display_leaderboard(data) -> void:
	var result = JSON.parse(data.get_string_from_utf8()).result
	#Is the leaderboard empty?
	if result.dreamlo.leaderboard == null:
		label.bbcode_text = "[center]Leaderboard unavailable"
	else:
		#Show leaderboard data
		label.bbcode_text = "[center]--- Leaderboard ---\n"
		#Show all results
		if result.dreamlo.leaderboard.entry is Dictionary:
			#One result
			add_leaderboard_entry(result.dreamlo.leaderboard.entry)
		else:
			#Multiple results
			for entry in result.dreamlo.leaderboard.entry:
				add_leaderboard_entry(entry)

func add_leaderboard_entry(entry:Dictionary) -> void:
	var txt = entry.name + " - " + entry.score
	#Highlight our name
	if entry.name == Global.leaderboard_name:
		txt = "[color=green]" + txt + "[/color]"
	#Add to label
	label.bbcode_text += txt + "\n"

#Called when the request is completed
func _on_HTTPRequest_request_completed(result, response_code, headers, body):
	#Make sure it's a success
	if result == HTTPRequest.RESULT_SUCCESS:
		display_leaderboard(body)
	else:
		print("Error handling HTTP request, result " + result)
