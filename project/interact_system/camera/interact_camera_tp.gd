extends Node3D
class_name InteractCameraTP3D

@export var external_cam_pivot : Vector3 = Vector3.ZERO
var lerp_speed = 5
var cam : Camera3D
var arm : SpringArm3D
var arm_pos : Node3D
var cam_leveler : Node3D
var real_rotation : Vector3 = Vector3.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
	cam_leveler = $CameraLeveler
	cam = $CameraLeveler/SeatCamera3D2
	arm = $SpringArm3D
	arm_pos = $SpringArm3D/LerpTo
