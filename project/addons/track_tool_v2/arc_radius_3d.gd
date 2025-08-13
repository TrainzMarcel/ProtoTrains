@tool
extends Marker3D
class_name ArcRadius3D
@export var update_single : bool = false :
	set(value):
		update_single = false
		if get_parent() is ArcConnector3D:
			get_parent().curve_update()

@export var radius : float = 50 :
	set(value):
		radius = value
		gizmo_extents = value
@export var flip_direction : bool = false
@export var tangent_angle : float = 0
@export var tangent_angle_degrees : float = 0
@export var tangent_vector : Vector3 = Vector3.ZERO
@export var normal_vector : Vector3 = Vector3.ZERO

func _init():
	gizmo_extents = radius

func _get_configuration_warnings():
	var warnings : Array[String] = []
#checking for problems
	if !get_parent() is ArcConnector3D:
		warnings.append("This node is meant to be a child of ArcConnector.")
	return warnings
