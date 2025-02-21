extends Node

var input_rotating = false
var prev_mouse_position
var next_mouse_position
var input_rotation_sensitivity = 0.2

var src_root : Node3D
var src_points : Array[Node3D]
var tgt_root : Node3D
var tgt_points : Array[Node3D]

var bAutoSolve := false
var bSolved := false

# NOTE: The matching process is calculated by index pairs, so the point count must be the same
var src_point_count = 5
var tgt_point_count = src_point_count

var point_sparseness = 30
var cloud_likeliness = 0.95

var rng = RandomNumberGenerator.new()

var r_mat = StandardMaterial3D.new()
var g_mat = StandardMaterial3D.new()

func make_debug_sphere(size, mat):
	var sphere = SphereMesh.new()
	sphere.radial_segments = 4
	sphere.rings = 4
	sphere.radius = size
	sphere.height = size*2
	
	sphere.surface_set_material(0, mat)
	# Add to meshinstance in the right place.
	var node = MeshInstance3D.new()
	node.mesh = sphere
	return node

func random_pos(sparseness):
	var tmp_x = rng.randf_range(-sparseness, sparseness)
	var tmp_y = rng.randf_range(-sparseness, sparseness)
	var tmp_z = rng.randf_range(-sparseness, sparseness)
	return Vector3(tmp_x, tmp_y, tmp_z)

func get_average_center(points : Array[Node3D]):
	var center := Vector3(0,0,0)
	for i: Node3D in points:
		center += i.position
	center /= len(points)
	return center

func rotate_around(obj, axis, angle):
	var rot = angle + obj.rotation.y
	obj.position = obj.position.rotated(axis, -rot)

func generateSourcePointCloud():
	var src_root = Node3D.new()
	var tmp_pt_list :Array[Node3D] = []
	src_root.name = "src_root"
	add_child(src_root)
	for i in range(src_point_count):
		var tmp_point = Node3D.new()
		tmp_point.name = "src_point_" + str(i)
		tmp_point.position = random_pos(point_sparseness)
		src_root.add_child(tmp_point)
		#add_child(tmp_point)
		tmp_pt_list.append(tmp_point)
		var tmp_sphere = make_debug_sphere(1.0, g_mat)
		tmp_point.add_child(tmp_sphere)
	return [src_root, tmp_pt_list]
	
func generateTargetPointCloud(src_root, src_points, likeliness):
	# Since we are looking for a transform match, it is best the target cloud is created based on the established source cloud
	var tgt_root = Node3D.new()
	var tmp_pt_list :Array[Node3D] = []
	tgt_root.name = "tgt_root"
	add_child(tgt_root)
	for i in range(tgt_point_count):
		var tmp_point = Node3D.new()
		tmp_point.name = "tgt_point_" + str(i)
		if likeliness > 0:
			# If target point cloud has less point than source, use source position with jitter
			tmp_point.position = src_points[i].position*likeliness + random_pos(point_sparseness*(1-likeliness))
		else:
			# If cannot find corresponding source point, create point randomly
			tmp_point.position = random_pos(point_sparseness)
		rotate_around(tmp_point, Vector3(1, 0, 0), 0.77)
		tgt_root.add_child(tmp_point)
		#add_child(tmp_point)
		tmp_pt_list.append(tmp_point)
		var tmp_sphere = make_debug_sphere(1.0, r_mat)
		tmp_point.add_child(tmp_sphere)
	return [tgt_root, tmp_pt_list]

func clearScene():
	src_root.queue_free()
	tgt_root.queue_free()

func createScene():
	var tmp_src_data = generateSourcePointCloud()
	src_root = tmp_src_data[0]
	src_points = tmp_src_data[1]
	var tmp_tgt_data = generateTargetPointCloud(src_root, src_points, cloud_likeliness)
	tgt_root = tmp_tgt_data[0]
	tgt_points = tmp_tgt_data[1]
	bSolved = false

func SolveKabsch():
	# Reference: https://zalo.github.io/blog/kabsch/
	# Given valid point clouds, calculate optimal transforms
	# Validate points
	if not (src_root and tgt_root):
		return
	# Calculate optimal translation
	var opt_trans = get_average_center(tgt_points) - get_average_center(src_points)
		
	# Calculate optimal rotation
	
	# First, get mean-centered position data of all points
	var src_center_delta:Vector3 = get_average_center(src_points)
	var tgt_center_delta:Vector3 = get_average_center(tgt_points)
	var src_points_mean_pos : Array[Vector3]
	for spt in src_points:
		src_points_mean_pos.append(spt.position - src_center_delta)
	var tgt_points_mean_pos : Array[Vector3]
	for tpt in tgt_points:
		tgt_points_mean_pos.append(tpt.position - tgt_center_delta)
		
	# Second, calculate 3x3 cross-covariance matrix
	var covariance = [Vector3(0,0,0),Vector3(0,0,0),Vector3(0,0,0)]
	for i in range(0, 3):
		for j in range(0, 3):
			for k in range(0, len(src_points)):
				covariance[i][j] += src_points_mean_pos[k][i] * tgt_points_mean_pos[k][j]
	#print("covariance:" + str(covariance))
	# Third, acquire polar decomposition of matrix
	var curQuaternion = Quaternion(0,0,0,1)
	var iterations = 20
	for iter in range(0, iterations):
		var quatBasis := Basis(curQuaternion)
		#print("Quat basis:" + str(quatBasis))
		# NOTE: Do not split the following long lines into multi-line like python, gdscript does not support it.
		var omegaDenom = abs((quatBasis.x).dot(covariance[0]) + (quatBasis.y).dot(covariance[1]) + (quatBasis.z).dot(covariance[2])) + 0.00000001
		var omega:Vector3 = (quatBasis.x).cross(covariance[0]) + (quatBasis.y).cross(covariance[1]) + (quatBasis.z).cross(covariance[2])
		#print("omegaDenom:" + str(omegaDenom))
		#print("omega:" + str(omega))
		omega /= omegaDenom
		#print("omega:" + str(omega))
		var w = omega.length()
		if w < 0.00000001:
			break
		#print(w)
		#print(omega.normalized())
		#print("=====")
		curQuaternion = Quaternion(omega.normalized(), w) * curQuaternion
		curQuaternion = curQuaternion.normalized()
	
	# Now we apply all transforms
	# We rotate the src_points data, as they are already mean-centered
	for i in range(0, len(src_points_mean_pos)):
		src_points_mean_pos[i] = curQuaternion * src_points_mean_pos[i]
	# Then we set the actual position of these points, by adding the delta value back to it
	for i in range(0, len(src_points)):
		src_points[i].position = src_points_mean_pos[i] + tgt_center_delta
		#tgt_points[i].position = tgt_points_mean_pos[i]
	

# Called when the node enters the scene tree for the first time.
func _ready():
	# Setup debugger materials
	r_mat.albedo_color = Color(1, 0, 0)
	r_mat.flags_unshaded = true
	g_mat.albedo_color = Color(0, 1, 0)
	g_mat.flags_unshaded = true
	
	rng.seed = hash("kabsch")
	createScene()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if bAutoSolve and not bSolved:
		SolveKabsch()
		bSolved = true
	if (Input.is_action_just_pressed("ui_left_click")):
		input_rotating = true
		prev_mouse_position = get_viewport().get_mouse_position()
	if (Input.is_action_just_released("ui_left_click")):
		input_rotating = false
		
	if (Input.is_action_just_pressed("ui_scroll_down")):
		$Camera3D.position.z += 1
	if (Input.is_action_just_pressed("ui_scroll_up")):
		$Camera3D.position.z -= 1
		
	if (input_rotating):
		next_mouse_position = get_viewport().get_mouse_position()
		if src_root and tgt_root:
			src_root.rotate_y((next_mouse_position.x - prev_mouse_position.x) * input_rotation_sensitivity * delta)
			src_root.rotate_x((next_mouse_position.y - prev_mouse_position.y) * input_rotation_sensitivity * delta)
			tgt_root.rotate_y((next_mouse_position.x - prev_mouse_position.x) * input_rotation_sensitivity * delta)
			tgt_root.rotate_x((next_mouse_position.y - prev_mouse_position.y) * input_rotation_sensitivity * delta)
		prev_mouse_position = next_mouse_position


func _on_solve_button_pressed() -> void:
	SolveKabsch()
	bSolved
	
func _on_ui_auto_solve_toggled(toggled_on: bool) -> void:
	bAutoSolve = toggled_on
	bSolved = false

func _on_ui_point_count_value_changed(value: float) -> void:
	src_point_count = int(value)
	tgt_point_count = int(value)
	clearScene()
	createScene()

func _on_ui_sparseness_value_changed(value: float) -> void:
	point_sparseness = value
	clearScene()
	createScene()

func _on_ui_likeliness_value_changed(value: float) -> void:
	cloud_likeliness = value
	clearScene()
	createScene()
