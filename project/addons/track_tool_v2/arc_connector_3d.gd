@tool
extends Node3D
class_name ArcConnector3D



@export var path_simplify_angle : float = 4
@export var modify_csgpolygons : bool = true
@export_category("Single Update")
@export var update_single : bool = false :
	set(_value):
		if Engine.is_editor_hint():
			update_single = false
			update_configuration_warnings()
			curve_update()

@export_category("Repeat Update")
@export var loop_interval_seconds : float = 0.25

@export var update_loop : bool = false :
	set(value):
		if Engine.is_editor_hint():
			update_loop = value
			while update_loop:
				await get_tree().create_timer(loop_interval_seconds).timeout
				curve_update()

#basis of calculations
var arc_radius_array : Array[ArcRadius3D]
#where the path3d control points will end up, local position relative to self (this node)
@export var position_array : Array[Vector3]
#path3d control point out vector, normal(right) vector and up vector
@export var basis_array : Array[Basis]

#csgpolygon meshes to extrude
var mesh_array : Array[CSGPolygon3D]
#path node
var path : Path3D
#if there are extra points, add to the idx to skip them
var idx_offset : int

func _get_configuration_warnings():
	var warnings : Array[String] = []
	var arc_count : int = 0
	var has_path_3d : bool = false
	
#checking for problems
	for i in get_children():
		if i is Path3D:
			has_path_3d = true
		
		if i is ArcRadius3D:
			arc_count = arc_count + 1
	
#returning warnings
	if !has_path_3d:
		warnings.append("This node requires a Path3D child.")
	if arc_count < 2:
		warnings.append("This node needs at least 2 ArcRadius3D children.")
	return warnings


func curve_update():
#making sure there are child nodes
	if get_child_count() == 0:
		update_loop = false
		return
	
	
#assign arc radius nodes
	arc_radius_array.clear()
	for node in get_children():
		#assign arcradius node
		if node is ArcRadius3D:
			arc_radius_array.append(node)
	
	
#assign path3d
	path = null
	for node in get_children():
		if node is Path3D:
			path = node
			break
	if path == null:
		#if no path3d child nodes, stop loop
		update_loop = false
		return
	#bezier curves are limited to 90 degrees per point
	#before they become non-circular

	#so <90 = 1 point
	#>90 = 2 points
	#>180 = 3 points
	#>270 = 4 points
	#>360 becomes 1 point again and curvature returns to normal
	#actually idk about this but its probably true in this case
	
#main part of script
	path.position = Vector3.ZERO
	var cur : Curve3D = path.curve
	
	var idx : int = 0
	position_array.clear()
	basis_array.clear()
	
	for node in arc_radius_array:
		var i : ArcRadius3D
		var j : ArcRadius3D
		i = node
	#making sure next point exists
	#if next is nonexistant, we reached the last point
		if !arc_radius_array.size() - 1 > idx:
			i.tangent_angle = 0
			i.tangent_angle_degrees = 0
			break
		
		
	#j is always next circle
		j = arc_radius_array[idx + 1]
	#right angle triangle stuff
		var opposite : float = 0
		var hypotenuse : Vector3 = Vector3.ZERO
		var angle : float = 0
		var adjacent : Vector3 = Vector3.ZERO
	#normal-direction offset of adjacent to connect circles
		@warning_ignore("unused_variable")#i hate this
		var normal : Vector3 = Vector3.ZERO
		var final : Vector3 = Vector3.ZERO
		
		#same overlapping radii cause major problems
		if i.position == j.position:
			return
		
		
	#this stays constant for all cases
		hypotenuse = j.position - i.position
		hypotenuse.y = 0
		
	#outer tangent 1A
		if !i.flip_direction and !j.flip_direction:
			opposite = i.radius - j.radius
			angle = asin(opposite / hypotenuse.length())
			adjacent = hypotenuse.rotated(Vector3.UP, angle + PI)
			adjacent = adjacent.normalized() * adjacent.dot(-hypotenuse.normalized())
			normal = adjacent.rotated(Vector3.UP, PI / 2).normalized() * i.radius
	#outer tangent 2
		elif i.flip_direction and j.flip_direction:
			opposite = i.radius - j.radius
			angle = asin(opposite / hypotenuse.length())
			adjacent = hypotenuse.rotated(Vector3.UP, -angle + PI)
			adjacent = adjacent.normalized() * adjacent.dot(-hypotenuse.normalized())
			normal = adjacent.rotated(Vector3.UP, PI / 2).normalized() * -i.radius
	#inner tangent 1
		elif !i.flip_direction and j.flip_direction:
			opposite = i.radius + j.radius
			angle = asin(opposite / hypotenuse.length())
			adjacent = hypotenuse.rotated(Vector3.UP, angle + PI)
			adjacent = adjacent.normalized() * adjacent.dot(-hypotenuse.normalized())
			normal = adjacent.rotated(Vector3.UP, PI / 2).normalized() * i.radius
	#inner tangent 2
		elif i.flip_direction and !j.flip_direction:
			opposite = i.radius + j.radius
			angle = asin(-opposite / hypotenuse.length())
			adjacent = hypotenuse.rotated(Vector3.UP, angle + PI)
			adjacent = adjacent.normalized() * adjacent.dot(-hypotenuse.normalized())
			normal = adjacent.rotated(Vector3.UP, PI / 2).normalized() * -i.radius
		
	#this also stays constant for all cases
		final = adjacent.normalized() * adjacent.normalized().dot(hypotenuse)
		i.tangent_vector = final
		i.normal_vector = normal
	#increment index
		idx = idx + 1
	
	
	
	
#new loop as i need to first calculate all tangent vectors before i can continue with angles
	idx = 0
	for node in arc_radius_array:
		var i : ArcRadius3D
		var j : ArcRadius3D
		i = node
	#making sure next point exists
	#if next is nonexistant, we reached the last point
		if !arc_radius_array.size() - 1 > idx:
			i.tangent_angle = 0
			i.tangent_angle_degrees = 0
			break
		
		
	#j.flip_direction true = right turn, false = left turn
	#this is crucial for knowing the true angle between these two vectors
	#as i dont always want the shortest angle
	#j is always next circle
		j = arc_radius_array[idx + 1]
		if j.flip_direction:
			#adding or subtracting TAU to measure the angle from the other direction
			j.tangent_angle = atan2(i.tangent_vector.z, i.tangent_vector.x) - atan2(j.tangent_vector.z, j.tangent_vector.x)
			if j.tangent_angle > 0:
				j.tangent_angle = j.tangent_angle - TAU
		else:
			j.tangent_angle = atan2(i.tangent_vector.z, i.tangent_vector.x) - atan2(j.tangent_vector.z, j.tangent_vector.x)
			if j.tangent_angle < 0:
				j.tangent_angle = j.tangent_angle + TAU
		j.tangent_angle_degrees = rad_to_deg(j.tangent_angle)
		
		
	#start point of "final" vector
		var new_basis : Basis = Basis()
		var normal : Vector3 = i.normal_vector
		
	#need to make sure these points get placed correctly
		new_basis.z = -i.tangent_vector.normalized()
		new_basis.x = normal.normalized()
	#normalized just in case
		new_basis.y = Vector3.UP
	#k constant, magic number for circular bezier curves
		var k : float = 0.5522847498
		var arc_angle = j.tangent_angle
		var prev_angle = i.tangent_angle
		
		#this is kinda stupid but i didnt architect this very well so this is the easiest way
		#if > 270 deg, 3 more points get added so angle gets split into 4 sections
		if abs(i.tangent_angle) > TAU * 0.75:
			prev_angle = prev_angle / 4
		#if > 180 deg, 2 more points get added so angle gets split into 3 sections
		elif abs(i.tangent_angle) > PI:
			prev_angle = prev_angle / 3
		#if > 90 deg, 1 point gets added so angle gets split into 2 sections
		elif abs(i.tangent_angle) > TAU * 0.25:
			prev_angle = prev_angle / 2
		
		
		#if > 270 deg, 3 more points get added so angle gets split into 4 sections
		if abs(j.tangent_angle) > TAU * 0.75:
			arc_angle = arc_angle / 4
		#if > 180 deg, 2 more points get added so angle gets split into 3 sections
		elif abs(j.tangent_angle) > PI:
			arc_angle = arc_angle / 3
		#if > 90 deg, 1 point gets added so angle gets split into 2 sections
		elif abs(j.tangent_angle) > TAU * 0.25:
			arc_angle = arc_angle / 2
		
		
		new_basis.z = new_basis.z * k * i.radius * abs(prev_angle / (PI * 0.5))
		basis_array.append(new_basis)
		position_array.append(normal + i.position)
		new_basis.z = -i.tangent_vector.normalized()
		
	#end point of "final" vector
		new_basis.z = new_basis.z * k * j.radius * abs(arc_angle / (PI * 0.5))
		basis_array.append(new_basis)
		var corrected_height : Vector3 = normal + i.tangent_vector + i.position 
		corrected_height.y = j.position.y
		position_array.append(corrected_height)
		new_basis.z = new_basis.z.normalized()
		
		
	#checking if i need to add points in between start and end point of the arc
		#if next next point doesnt exist, dont add any more points
		if arc_radius_array.size() - 2 > idx:
			
			#need to flip this value so the points dont
			#end up on the wrong side of the arcradius node
			var radius = j.radius
			if i.flip_direction != j.flip_direction:
				radius = -radius
			
		#if > 270 deg, add 3 more points
			if abs(j.tangent_angle) > TAU * 0.75:
				position_array.append(normal.rotated(Vector3.UP, arc_angle).normalized() * radius + j.position)
				basis_array.append(new_basis.rotated(Vector3.UP, arc_angle) * k * j.radius * abs(arc_angle / (PI * 0.5)))
				position_array.append(normal.rotated(Vector3.UP, arc_angle * 2).normalized() * radius + j.position)
				basis_array.append(new_basis.rotated(Vector3.UP, arc_angle * 2) * k * j.radius * abs(arc_angle / (PI * 0.5)))
				position_array.append(normal.rotated(Vector3.UP, arc_angle * 3).normalized() * radius + j.position)
				basis_array.append(new_basis.rotated(Vector3.UP, arc_angle * 3) * k * j.radius * abs(arc_angle / (PI * 0.5)))
		#if > 180 deg, add 2 more points
			elif abs(j.tangent_angle) > PI:
				position_array.append(normal.rotated(Vector3.UP, arc_angle).normalized() * radius + j.position)
				basis_array.append(new_basis.rotated(Vector3.UP, arc_angle) * k * j.radius * abs(arc_angle / (PI * 0.5)))
				position_array.append(normal.rotated(Vector3.UP, arc_angle * 2).normalized() * radius + j.position)
				basis_array.append(new_basis.rotated(Vector3.UP, arc_angle * 2) * k * j.radius * abs(arc_angle / (PI * 0.5)))
		#if > 90 deg, add 1 more point
			elif abs(j.tangent_angle) > TAU * 0.25:
				position_array.append(normal.rotated(Vector3.UP, arc_angle).normalized() * radius + j.position)
				basis_array.append(new_basis.rotated(Vector3.UP, arc_angle) * k * j.radius * abs(arc_angle / (PI * 0.5)))
	#increment index
		idx = idx + 1
	
	
#go through curve positions and set control point position according to position and basis array
	idx = 0
	cur.clear_points()
	
	while idx < position_array.size():
		cur.add_point(position_array[idx])
#set out and in point positions according to basis array
		cur.set_point_out(idx, -basis_array[idx].z)
		cur.set_point_in(idx, basis_array[idx].z)
		"TODO"#add banking to turns if specified in arcradius
		#cur.set_point_tilt(idx, 0)
		#increment loop counter
		idx = idx + 1
	
	
#assign csgmeshes
	#by this point there should be a path
	for i in get_children():
		if i is CSGPolygon3D and modify_csgpolygons:
			i.position = Vector3.ZERO
			i.path_simplify_angle = path_simplify_angle
			#make sure its in path mode before assigning a path
			i.mode = 2 #MODE_PATH
			i.path_local = true
			#it needs an absolute node path for some reason
			i.path_node = path.get_path()
