extends Node

onready var animation = $AnimationPlayer

#Are we in the middle of a transition right now?
var is_mid_transition : bool = false

#Clear color
func _ready() -> void:
	$ColorRect.color = Color(0,0,0,0)

#Transition to another scene
func transition_to(dest_scene:String, in_transition:String="Fade", out_transition:String="Fade") -> void:
	if not is_mid_transition:
		animation.play(in_transition)
		#Wait for the animation to end
		yield(animation,"animation_finished")
# warning-ignore:return_value_discarded
		get_tree().change_scene(dest_scene)
		animation.play_backwards(out_transition)
		is_mid_transition = false
