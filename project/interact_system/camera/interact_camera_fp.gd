extends Camera3D
class_name InteractCameraFP3D

#only allows specific objects to be assigned
@export var assigned_interact : Node
@export var tp_cam : InteractCameraTP3D
@export var interact_raycast : RayCast3D
@export var interact_text : RichTextLabel

var mouse_sensitivity : float = 0.2
var rotation_limit : float = 80
var desired_fov : float = 90

# Called when the node enters the scene tree for the first time.
#func _ready():
#	interact_raycast = $RayCast3D
#	interact_text = $RichTextLabel
