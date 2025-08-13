extends Node
class_name InteractManager

#˙ ͜ʟ˙

@export var player_append_on_ready : Array[Node]
@export var active_array : Array[Node]

"""
PLANNING
x 1. get player and cams working
x 2. get seat working
  3. get terminal working
  4. get button working
  5. reconfigure scenes
"""



# Called when the node enters the scene tree for the first time.
func _ready():
	for i in player_append_on_ready:
		append_remove_active(i, true)
		append_remove_active(i.fp_cam, true)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	for node in active_array:
		if node is InteractCameraFP3D:
			camera_fp_process(delta, node)


func _input(event):
	for node in active_array:
		if node is InteractPlayer:
			player_input(event, node)
		if node is InteractCameraFP3D:
			camera_fp_input(event, node)
		if node is InteractSeat:
			seat_input(event, node)


func _physics_process(delta):
	for node in active_array:
		if node is InteractPlayer:
			player_physics_process(delta, node)

#handles dependencies and/or initialization of nodes as well as
#setting them to active
func append_remove_active(input : Node, append : bool):
	if input is InteractCameraFP3D:
		if append:
			input.interact_text.visible = true
			input.current = true
			input.get_node("Control").visible = true
			active_array.append(input)
		else:
			input.interact_text.visible = false
			input.get_node("Control").visible = false
			active_array.erase(input)
	
	
	if input is InteractPlayer:
		if append:
			input.get_node("MeshInstance3D").visible = true
			input.freeze = false
			input.collider.disabled = false
			input.is_control_active = true
			active_array.append(input)
		else:
			input.is_control_active = false
			input.freeze = true
			input.collider.disabled = true
			input.get_node("MeshInstance3D").visible = false
			active_array.erase(input)
	
	
	if input is InteractSeat:
		if append:
			active_array.append(input)
		else:
			active_array.erase(input)
			input.fp_cam.rotation = Vector3.ZERO


func player_physics_process(delta, plr : InteractPlayer):
	var leg_force = Vector3.ZERO
	if plr.leg_raycast.is_colliding():
		plr.ground_vel = Vector3.ZERO
		plr.drag_coefficient = plr.drag_ground
		plr.walk_accel_coefficient = plr.walk_accel_ground
		
		#offset means how far the spring is compressed
		var leg_offset = plr.leg_target_length - plr.leg_raycast.to_local(plr.leg_raycast.get_collision_point()).y * -1
		#calculating relative spring velocity for damping
		var leg_relative_vel = (leg_offset - plr.prev_offset) / delta
		plr.prev_offset = leg_offset
		
		#calculating final spring force
		leg_force.y = (plr.leg_stiffness * leg_offset) + (leg_relative_vel * plr.leg_damping)
		#limit leg force to not bounce up too quickly
		leg_force.y = min(plr.max_leg_force, leg_force.y)
		
		#dont pull downward
		leg_force.y = max(leg_force.y, 0)
		
		
		
		#push back against rigidbodies
		if plr.leg_raycast.get_collider() is RigidBody3D:
			var other : RigidBody3D = plr.leg_raycast.get_collider()
			var pos = plr.leg_raycast.get_collision_point()
			#/30 because its too strong and 30 feels like the right number
			other.apply_force(-leg_force / 30, -(other.global_position - pos))
		#if standing on a rigidbody or kinematic body, "follow" it
		if plr.leg_raycast.get_collider() is RigidBody3D:
			var other : RigidBody3D = plr.leg_raycast.get_collider()
			plr.ground_vel = other.linear_velocity
		
		#do the same thing here
		#if leg_raycast.get_collider() is StaticBody3D:
		
		#use ground_vel to calculate relative velocity
		#(relative to the ground that is stood on)
		plr.rel_vel = plr.linear_velocity - plr.ground_vel
	else:
		leg_force = Vector3.ZERO
		plr.drag_coefficient = plr.drag_air
		plr.walk_accel_coefficient = plr.walk_accel_air
	
	
	
	
#speed limit
	var walk_force = plr.wish_dir * plr.walk_accel_coefficient
	if Input.is_action_pressed("player_run"):
		if plr.rel_vel.length() > plr.run_speed_limit:
			walk_force = walk_force / 20
	else:
		if plr.rel_vel.length() > plr.walk_speed_limit:
			walk_force = walk_force / 20
	
	
#applying drag_force in the left and right direction to counteract any sideways sliding
	var drag_force = Vector3.ZERO
	var slide_counter_force = plr.rel_vel - plr.wish_dir * plr.rel_vel.dot(plr.wish_dir)
	slide_counter_force = slide_counter_force * -plr.drag_coefficient / 4
	slide_counter_force.y = 0
	
	
	#apply drag when above threshold and no input is given
	if plr.rel_vel.length() > plr.drag_vel_threshold and walk_force == Vector3.ZERO:
		drag_force = -plr.rel_vel.normalized() * plr.drag_coefficient
		drag_force.y = 0
	#when vel is low enough, set it to 0
	elif plr.rel_vel.length() > plr.drag_vel_threshold / 10.0 and walk_force == Vector3.ZERO:
		plr.linear_velocity.x = plr.ground_vel.x
		plr.linear_velocity.z = plr.ground_vel.z
	
	
	#applying all calculated forces
	plr.apply_central_force((walk_force + leg_force + drag_force + slide_counter_force) * delta)
	#if leg_raycast.get_collider() == RigidBody3D


func player_input(event : InputEvent, plr : InteractPlayer):
	if plr.is_control_active:
	#cursor unlock
		if event.is_action_pressed("cam_hide_mouse"):
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
		
	#jump
		if Input.is_action_just_pressed("player_jump") && plr.is_control_active && plr.leg_raycast.is_colliding():
			plr.linear_velocity.y = plr.jump_speed
		
		
		
	#calculate walking/moving vector
		plr.wish_dir.z = -Input.get_axis("player_walk_back", "player_walk_forward")
		plr.wish_dir.x = Input.get_axis("player_walk_left", "player_walk_right")
		plr.wish_dir = plr.wish_dir.normalized().rotated(Vector3.UP, plr.fp_cam.rotation.y)


func camera_fp_process(delta, cam : InteractCameraFP3D):
	cam.fov = lerp(cam.fov, cam.desired_fov, 8 * delta)
	
	if cam.tp_cam == null:
		return
	
	"TODO"#third person cam code is very quickly cobbled together, clean up when theres the time 
	cam.tp_cam.cam.global_rotation_degrees = cam.tp_cam.real_rotation
	cam.tp_cam.cam.global_rotation_degrees.y = cam.tp_cam.real_rotation.y + cam.tp_cam.cam.global_rotation_degrees.y
	
	if cam.assigned_interact is InteractSeat:
		cam.tp_cam.arm.global_position = cam.global_position + cam.assigned_interact.external_cam_pivot.rotated(Vector3.UP, cam.global_rotation.y)
	else:
		cam.tp_cam.arm.global_position = cam.global_position + cam.tp_cam.external_cam_pivot.rotated(Vector3.UP, cam.global_rotation.y)
	
	cam.tp_cam.arm.global_rotation_degrees = Vector3.ZERO + cam.tp_cam.real_rotation
	cam.tp_cam.cam_leveler.global_rotation_degrees = Vector3.ZERO
	cam.tp_cam.cam.global_rotation_degrees = cam.tp_cam.real_rotation
	cam.tp_cam.cam.rotation_degrees.x = clamp(cam.tp_cam.cam.rotation_degrees.x, -80, 80)
	cam.tp_cam.cam.global_position = cam.tp_cam.cam.global_position.lerp(cam.tp_cam.arm_pos.global_position, cam.tp_cam.lerp_speed * delta)


func camera_fp_input(event : InputEvent, cam : InteractCameraFP3D):
#zoom
	if Input.is_action_pressed("cam_zoom_in"):
		cam.desired_fov = 45.0
	elif !Input.is_action_pressed("cam_zoom_in"):
		cam.desired_fov = 90.0
	
	
	if cam.tp_cam != null:
		if event.is_action_pressed("third_person"):
			if cam.current:
				#cam.tp_cam.rotation = cam.rotation
				cam.tp_cam.cam.current = true
			else:
				cam.current = true
			
		if event is InputEventMouseButton and cam.tp_cam.cam.current:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				cam.tp_cam.arm.spring_length = max(cam.tp_cam.arm.spring_length - 1, 2)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				cam.tp_cam.arm.spring_length = cam.tp_cam.arm.spring_length + 1
	
	"TODO"#if event is InputEventMouseMotion && Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		#rotate camera
		#seat.real_rotation.y = seat.real_rotation.y - event.relative.x * seat.current_user.mouse_sensitivity
		#seat.real_rotation.x = seat.real_rotation.x - event.relative.y * seat.current_user.mouse_sensitivity
	
	
	
	
	print("MOW")
	
#rotate camera
	if event is InputEventMouseMotion && Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		print("MOW1")
		cam.rotation_degrees.y = cam.rotation_degrees.y - event.relative.x * cam.mouse_sensitivity
		cam.rotation_degrees.x = cam.rotation_degrees.x - event.relative.y * cam.mouse_sensitivity
		print(cam.rotation_degrees)
	#to limit cam rotation
		cam.rotation_degrees.x = clamp(cam.rotation_degrees.x, -cam.rotation_limit, cam.rotation_limit)
	
#interaction
	if Input.is_action_just_pressed("player_interact"):
		if cam.interact_raycast.get_collider() != null:
			if cam.interact_raycast.get_collider().has_method("button_identifier"):
				var button_node : InteractButton = cam.interact_raycast.get_collider()
				if button_node.button_type == button_node.button_type_enum.toggle_switch:
					button_node.lever_position = button_node.lever_position + 1
					if button_node.lever_position > button_node.lever_position_count:
						button_node.lever_position = 0
				button_node.is_active = bool(button_node.lever_position)
			elif cam.interact_raycast.get_collider().has_method("seat_identifier"):
				var seat_node : InteractSeat = cam.interact_raycast.get_collider()
				if cam.assigned_interact is InteractPlayer:
					#remove camera and player from active array
					append_remove_active(cam, false)
					append_remove_active(cam.assigned_interact, false)
					#add other camera and seat to active array
					append_remove_active(seat_node.fp_cam, true)
					seat_node.current_user = cam.assigned_interact
					append_remove_active(seat_node, true)
				elif cam.assigned_interact is InteractSeat:
					append_remove_active(cam, false)
					append_remove_active(cam.assigned_interact, false)
					#add other camera and seat to active array
					append_remove_active(seat_node.fp_cam, true)
					seat_node.current_user = cam.assigned_interact.current_user
					append_remove_active(seat_node, true)
	
	var ray_result = cam.interact_raycast.get_collider()
	if ray_result != null && (ray_result.has_method("button_identifier") || ray_result.has_method("seat_identifier")):
		cam.interact_text.text = cam.interact_raycast.get_collider().prompt
	else:
		cam.interact_text.text = ""


func seat_input(event : InputEvent, seat : InteractSeat):
	if Input.is_action_pressed("seat_exit"):
		#remove seat from active
		append_remove_active(seat, false)
		append_remove_active(seat.fp_cam, false)
		#add camera and player to active
		append_remove_active(seat.current_user.fp_cam, true)
		append_remove_active(seat.current_user, true)
		
		#if seat is upside down, use upside down exit position
		if seat.global_transform.basis.y.dot(Vector3.UP) < 0:
			seat.current_user.global_position = seat.to_global(seat.upside_down_exit_position.rotated(Vector3.UP, seat.rotation.y))
		else:
			seat.current_user.global_position = seat.to_global(seat.exit_position.rotated(Vector3.UP, seat.rotation.y))
		seat.current_user = null

"TODO"#old code
func end_terminal_interact(button_node : InteractButton, player_node : InteractPlayer):
	player_node.is_control_active = true
	player_node.desired_fov = 90.0
	button_node.is_active = false
	button_node.current_user = null



"func interact_seat_input(event, seat : InteractSeat):"
#	if !seat.is_occupied:
#		return
#	
#	if event is InputEventMouseMotion && Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
#		#rotate camera
#		seat.real_rotation.y = seat.real_rotation.y - event.relative.x * seat.current_user.mouse_sensitivity
#		seat.real_rotation.x = seat.real_rotation.x - event.relative.y * seat.current_user.mouse_sensitivity
#		
#		#to limit cam rotation
#		seat.seat_cam.rotation_degrees.x = clamp(seat.seat_cam.rotation_degrees.x, -80, 80)
#		seat.exterior_cam.rotation_degrees.x = clamp(seat.seat_cam.rotation_degrees.x, -80, 80)
#	
#	if event.is_action("seat_exit") && seat.current_user != null:
#		#dont forget to do the exit teleport in here
#		end_seat_interact(seat, seat.current_user)
#		return

#	if event.is_action_pressed("third_person"):
#		if seat.seat_cam.current:
#			seat.exterior_cam.make_current()
#		else:
#			seat.seat_cam.make_current()
#		
#	if event is InputEventMouseButton:
#		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
#			seat.arm.spring_length = max(seat.arm.spring_length - 1, 2)
#		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
#			seat.arm.spring_length = seat.arm.spring_length + 1
#	
