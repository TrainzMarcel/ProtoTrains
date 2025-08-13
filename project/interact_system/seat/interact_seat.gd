extends Area3D
class_name InteractSeat

@export var external_cam_pivot : Vector3 = Vector3.ZERO
@export var current_user : InteractPlayer = null
@export var prompt : String = "prompt"
@export var exit_position : Vector3 = Vector3.ZERO
@export var upside_down_exit_position : Vector3 = Vector3.ZERO


var fp_cam : InteractCameraFP3D

func _ready():
	fp_cam = $"InteractCameraFP"

func seat_identifier():
	pass
