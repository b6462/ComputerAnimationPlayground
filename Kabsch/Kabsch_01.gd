extends Node


var src_root : Node3D
var src_points : Array[Node3D]
var tgt_root : Node3D
var tgt_points : Array[Node3D]

var src_point_count = 5
var tgt_point_count = 5

var point_sparseness = 20
var cloud_likeliness = 0.8

var rng = RandomNumberGenerator.new()

var r_mat = StandardMaterial3D.new()
var g_mat = StandardMaterial3D.new()

func random_pos(sparseness):
	var tmp_x = rng.randf_range(-sparseness, sparseness)
	var tmp_y = rng.randf_range(-sparseness, sparseness)
	var tmp_z = rng.randf_range(-sparseness, sparseness)
	return Vector3(tmp_x, tmp_y, tmp_z)

func generateSourcePointCloud():
	var src_root = Node3D.new()
	var tmp_pt_list :Array[Node3D] = []
	src_root.name = "src_root"
	add_child(src_root)
	for i in range(src_point_count):
		var tmp_point = Node3D.new()
		tmp_point.name = "src_point_" + str(i)
		tmp_point.position = random_pos(point_sparseness)
		print(tmp_point.position)
		src_root.add_child(tmp_point)
		tmp_pt_list.append(tmp_point)
		var tmp_sphere = make_debug_sphere(1.0, r_mat)
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
		if i < len(src_points) and likeliness > 0:
			# If target point cloud has less point than source, use source position with jitter
			tmp_point.position = src_points[i].position*likeliness + random_pos(point_sparseness*(1-likeliness))
		else:
			# If cannot find corresponding source point, create point randomly
			tmp_point.position = random_pos(point_sparseness)
		tgt_root.add_child(tmp_point)
		tmp_pt_list.append(tmp_point)
		var tmp_sphere = make_debug_sphere(1.0, g_mat)
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

func SolveKabsch():
	# Solver
	# Validate points
	if not (src_root and tgt_root):
		return
	pass

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
	if src_root and tgt_root:
		SolveKabsch()

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
