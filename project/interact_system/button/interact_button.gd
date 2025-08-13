extends Area3D
class_name InteractButton

@export var is_active : bool = false
#current position of the switch
@export var lever_position : int = 0
#how many positions the lever has
@export var lever_position_count : int = 1
@export var prompt : String = "prompt"
@export var button_type : button_type_enum = button_type_enum.push_button
#for drag modes
@export var drag_direction : Vector2 = Vector2.RIGHT
@export var drag_multiplier : float = 1

enum button_type_enum
{
	push_button,
	toggle_switch,
	drag_button_snap,
	drag_switch_snap#,
	#drag_button_smooth,
	#drag_switch_smooth
}

func button_identifier():
	pass
