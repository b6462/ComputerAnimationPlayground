extends Node3D

var dragging := false
var drag_target: RigidBody3D
var original_mouse_pos := Vector2(0, 0)
@onready var camera := $Camera3D
@export var control_points: Array[Node3D]
@export var target_mesh: MeshInstance3D

var orig_ctrl_pts: PackedVector3Array
var orig_mesh_vts: PackedVector3Array
var dfrm_mesh_vts: PackedVector3Array
var dfrm_mesh: ArrayMesh
var weight = 1
var mdt := MeshDataTool.new()

func _ready():
	# From primitiveMesh to ArrayMesh to mdt
	var sft := SurfaceTool.new()
	sft.create_from(target_mesh.mesh, 0)
	var tgt_arr_mesh := sft.commit()
	dfrm_mesh = tgt_arr_mesh
	mdt.create_from_surface(tgt_arr_mesh, 0)
	for vtx in range(mdt.get_vertex_count()):
		var vert = mdt.get_vertex(vtx)
		orig_mesh_vts.append(vert)
		dfrm_mesh_vts.append(vert)
	for ctrl in control_points:
		orig_ctrl_pts.append(ctrl.position)

func _input(event):
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton

		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				var ray_origin = camera.project_ray_origin(get_viewport().get_mouse_position())
				var ray_direction = camera.project_ray_normal(get_viewport().get_mouse_position())
				var ray_end = ray_origin + ray_direction * 100.0
				var space_state = get_world_3d().direct_space_state
				var test = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
				var intersect = space_state.intersect_ray(test)
				if not intersect.is_empty():
					var collider = intersect["collider"]
					print(collider)
					if collider is RigidBody3D:
						dragging = true
						drag_target = collider
						original_mouse_pos = get_viewport().get_mouse_position()
			else:
				if dragging:
					dragging = false
					drag_target.sleeping = true
					drag_target = null

func _process(delta):
	# Update control points
	if dragging and drag_target:
		var current_mouse_pos = get_viewport().get_mouse_position()
		var delta_pos = current_mouse_pos - original_mouse_pos
		delta_pos *= 0.3
		drag_target.global_position += Vector3(delta_pos.x, -delta_pos.y, 0)*delta
		original_mouse_pos = current_mouse_pos
		
	# Update mesh deformation
	for v in range(0, orig_mesh_vts.size()):
		var totalWeight = 0
		var tmp_ctrlPointWeights:= []
		for c in range(0, control_points.size()):
			tmp_ctrlPointWeights.append(1/pow((orig_mesh_vts[v]-orig_ctrl_pts[c]).length(), weight))
			totalWeight += tmp_ctrlPointWeights[c]
		for c in range(control_points.size()):
			tmp_ctrlPointWeights[c] /= totalWeight
		
		var displacement := Vector3(0,0,0)
		for c in range(control_points.size()):
			var cur_ctrl_point: Vector3 = control_points[c].position
			var ctrl_disp: Vector3 = cur_ctrl_point - orig_ctrl_pts[c]
			var vert_to_ctrl: Vector3 = orig_mesh_vts[v] - orig_ctrl_pts[c]
			var rot_disp: Vector3 = control_points[c].rotation * vert_to_ctrl - vert_to_ctrl
			displacement += (ctrl_disp + rot_disp) * tmp_ctrlPointWeights[c]
		dfrm_mesh_vts[v] = orig_mesh_vts[v] + displacement
		
	# Update mesh vert position with dfrm_mesh_vts data
	for vtx in range(mdt.get_vertex_count()):
		mdt.set_vertex(vtx, dfrm_mesh_vts[vtx])
	mdt.commit_to_surface(dfrm_mesh)
	target_mesh.mesh = dfrm_mesh
