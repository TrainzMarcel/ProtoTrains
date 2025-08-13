extends RigidBody3D
class_name InteractPlayer

@export var is_control_active : bool = true

@export var leg_raycast : RayCast3D
@export var fp_cam : InteractCameraFP3D
var desired_fov : float = 90.0

#for staying on moving platforms
var ground_vel : Vector3
var rel_vel : Vector3

@export var walk_speed_limit : float = 5
@export var run_speed_limit : float = 10
@export var walk_accel_ground : float = 600
@export var walk_accel_air : float = 300
var walk_accel_coefficient : float
@export var drag_ground : float = 600
@export var drag_air : float = 50
var drag_coefficient : float
@export var drag_vel_threshold : float = 1

@export var jump_speed : float = 5
@export var leg_damping : float = 0.2
@export var leg_stiffness = 3000
@export var max_leg_force = 4000
@export var leg_target_length : float = 1
var prev_offset : float = 0
var wish_dir : Vector3 = Vector3.ZERO

@export var collider : CollisionShape3D


func _ready():
	if rotation.y != 0:
		fp_cam.rotation.y = rotation.y
		rotation.y = 0
	
	max_leg_force = max_leg_force * mass
	leg_stiffness = leg_stiffness * mass
	leg_damping = leg_damping * leg_stiffness
	walk_accel_air = walk_accel_air * mass
	walk_accel_ground = walk_accel_ground * mass
	drag_ground = drag_ground * mass
	drag_air = drag_air * mass
	
	#setting mouse to be invisible and to stay centered
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
