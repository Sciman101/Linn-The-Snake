extends Node2D

#Load graphics tiles
onready var frames = preload("res://Textures/Frames.png")

#Game constants
const DIRECTIONS = [Vector2.RIGHT,Vector2.UP,Vector2.LEFT,Vector2.DOWN]
const TILE_SIZE : int = 32
const TILE_VEC : Vector2 = Vector2.ONE * TILE_SIZE
const WORLD_SIZE : int = 16

const GROW_AMOUNTS := [1,2,4]
const GRACE_PERIODS := [2,1,0] #How many frames are we allowed to press against a wall?
const GAME_SPEEDS := [0.12,0.1,0.08]

const SCORE_TEMPLATE : String = "Score: %d"
const GAMEOVER_TEMPLATE : String = "Game Over!\nScore: %d\nBest:%d"

onready var game_clock = $GameClock
onready var score_label = $UI/ScoreLabel
onready var collect_sfx = $SFX/SodaCollect
onready var hurt_sfx = $SFX/Hurt

onready var gameover_screen = $UI/GameOver
onready var gameover_label = $UI/GameOver/GameOverLabel
onready var gameover_retry_label = $UI/GameOver/GameOverLabel2

var frame : int = 0 #Animation frame

var grow_amount : int
var grace_period : int

var segments = [Vector2(WORLD_SIZE/2,WORLD_SIZE/2)] #Collection of snake segments
var direction : Vector2 = Vector2.UP #Direction the snake is currently headed in
var facing : int = 1 #Used for animation
var food : Vector2 = Vector2(-1,-1) #Where is the food located?
var grow_allowance : int = 0 #How much 'slack' do we have on the tail
var score : int = 0 #What's our score

var grace : int #How many frames can we spend against a wall before we face full life consqeuences

var game_over : bool = false
var gameover_selection : int = 0

func _ready() -> void:
	gameover_screen.visible = false
	
	#Hide boris
	$Boris.visible = rand_range(0,1000) <= 1
	
	#Setup difficulty
	grow_amount = GROW_AMOUNTS[Global.difficulty]
	grace_period = GRACE_PERIODS[Global.difficulty]
	grace = grace_period
	
	#Update this
	update_gameover_menu()
	
	#Enable input handling
	set_process_input(true)
	#Don't need these!
	set_process(false)
	set_physics_process(false)
	#Add a little more
	# warning-ignore:unused_variable
	for i in range(2):
		segments.push_back(segments.back()+Vector2.DOWN)

#Handle incoming input
func _input(event:InputEvent) -> void:
	if event.is_action_type():
		
		#If we're dead, don't do anything
		if not game_over:
			#Start moving
			if game_clock.is_stopped():
				game_clock.start(GAME_SPEEDS[Global.difficulty])
				#Mix up where the food is
				randomize_food_location()
			
			#Determine direction to move
			if event.is_action_pressed("right"): try_set_direction(0)
			elif event.is_action_pressed("left"): try_set_direction(2)
			elif event.is_action_pressed("up"): try_set_direction(1)
			elif event.is_action_pressed("down"): try_set_direction(3)
		
		else:
			#Handle game over screen!
			if event.is_action_pressed("right"):
				gameover_selection = wrapi(gameover_selection+1,0,3)
				update_gameover_menu()
			elif event.is_action_pressed("left"):
				gameover_selection = wrapi(gameover_selection-1,0,3)
				update_gameover_menu()
			if event.is_action_pressed("accept"):
				if gameover_selection == 0:
					Transition.transition_to("res://Game.tscn")
				elif gameover_selection == 1:
					Transition.transition_to("res://Menu.tscn")
				else:
					#Go to leaderboard screen
					Transition.transition_to("res://Leaderboard.tscn")
				#Ignore input
				set_process_input(false)

func update_gameover_menu() -> void:
	if gameover_selection == 0:
		gameover_retry_label.text = "[Restart] Menu Leaderboard"
	elif gameover_selection == 1:
		gameover_retry_label.text = "Restart [Menu] Leaderboard"
	else:
		gameover_retry_label.text = "Restart Menu [Leaderboard]"

#Attempt to set the direction to a certain value
func try_set_direction(dir:int) -> void:
	#Make sure we don't already have something in that direction
	var dvec = DIRECTIONS[dir]
	var next_pos = segments.front() + dvec
	if facing != dir and not next_pos in segments and point_in_world(next_pos):
		direction = dvec
		facing = dir
		#Force the snake to move
		_on_Timer_timeout()
		game_clock.start()

#Try and move the snake
func move_snake() -> void:
	#Calculate next position
	var next_pos = segments.front() + direction
	#Make sure we aren't hitting anything
	if point_in_world(next_pos) and not next_pos in segments:
		#Add new head
		segments.push_front(next_pos)
		#Remove previous tail if we have room to
		if grow_allowance <= 0:
			segments.pop_back()
		else:
			grow_allowance -= 1
		
		#Check to see if we've hit the food
		if food in segments:
			
			score += 1
			score_label.text = SCORE_TEMPLATE % score
			
			collect_sfx.play()
			
			randomize_food_location()
			grow_allowance += grow_amount
		
		#Reset grace
		grace = grace_period
		
	else:
		#Whoops, we hit the wall
		on_snake_collision()

#Check if a point lies in the world
func point_in_world(point:Vector2) -> bool:
	return point.x > 0 and point.y > 0 and point.x < WORLD_SIZE-1 and point.y < WORLD_SIZE-1

#Pick a random spot for the food
func randomize_food_location() -> void:
	while food in segments or not point_in_world(food):
		food = Vector2(randi()%(WORLD_SIZE-1)+1,randi()%(WORLD_SIZE-1)+1)

#Called when we hit something
func on_snake_collision() -> void:
	if grace <= 0:
		#Show game over screen
		show_gameover()
	else:
		grace -= 1

func show_gameover() -> void:
	
	#Stop game, temporarily disable input
	game_over = true
	game_clock.stop()
	set_process_input(false)
	
	#Update scores
	Global.update_best(score)
	
	#Show game over screen
	gameover_screen.visible = true
	gameover_label.text = GAMEOVER_TEMPLATE % [score,Global.current_best()]
	score_label.visible = false
	
	hurt_sfx.play()
	
	#Shake the screen
	var init_pos = gameover_screen.rect_position
	for i in range(30):
		yield(get_tree(),"idle_frame")
		var x = 30-i
		gameover_screen.rect_position = init_pos + Vector2(rand_range(-x,x),rand_range(-x,x))
	gameover_screen.rect_position = init_pos
	
	#Re-enable input handling
	set_process_input(true)

#Draw the snake path
func _draw() -> void:
	var segment_index : int = 0
	var end_index : int = segments.size()-1
	for segment in segments:
		
		#What tile should we end up drawing?
		var tile_to_draw : int = -1
		
		if segment_index == 0:
			#Drawing linn's body
			tile_to_draw = 3 * facing + pingpong_frame()
		elif segment_index < end_index:
			#Get previous and next segment
			var seg_prev = segments[segment_index+1]
			var seg_next = segments[segment_index-1]
			
			if seg_prev.y == segment.y and seg_next.y == segment.y:
				tile_to_draw = 13 #Horizontal
			elif seg_prev.x == segment.x and seg_next.x == segment.x:
				tile_to_draw = 12 #Vertical
			
			elif (seg_prev.x < segment.x and seg_next.y > segment.y) or (seg_prev.y > segment.y and seg_next.x < segment.x):
				tile_to_draw = 15
			elif (seg_prev.y > segment.y and seg_next.x > segment.x) or (seg_prev.x > segment.x and seg_next.y > segment.y):
				tile_to_draw = 14
			
			elif (seg_prev.x < segment.x and seg_next.y < segment.y) or (seg_prev.y < segment.y and seg_next.x < segment.x):
				tile_to_draw = 17
			elif (seg_prev.y < segment.y and seg_next.x > segment.x) or (seg_prev.x > segment.x and seg_next.y < segment.y):
				tile_to_draw = 16
		
		elif segment_index == end_index:
			#End of the tail!
			#What's behind us?
			var seg_next = segments[segment_index-1]
			if seg_next.x > segment.x:
				tile_to_draw = 20
			elif seg_next.x < segment.x:
				tile_to_draw = 18
			elif seg_next.y > segment.y:
				tile_to_draw = 19
			else:
				tile_to_draw = 21
		
		#Do the drawing
		draw_tile(segment,tile_to_draw)
		segment_index += 1
# warning-ignore:integer_division
	draw_tile(food,22+(frame/2))

#Draw a specific game tile
func draw_tile(pos:Vector2,tile:int) -> void:
	# warning-ignore:integer_division
	var tile_sprite_pos = Vector2(tile%3,tile/3)*TILE_SIZE
	draw_texture_rect_region(frames,Rect2(pos*TILE_SIZE,TILE_VEC),Rect2(tile_sprite_pos,TILE_VEC))

#Helper to enable ping pong style animation
func pingpong_frame() -> int:
	#Wrap frame to 1 of 4
	var mframe = frame % 4
	if mframe == 3:
		return 1
	else: return mframe

#Actually move the snake and update
func _on_Timer_timeout():
	move_snake()
	update()
	frame = wrapi(frame+1,0,8)
