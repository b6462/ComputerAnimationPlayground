extends Node
# NOTE: To move the control spheres, go to remote mode and move it in the editor
@export var ctrl_points: Array[Node3D]
@export var tgt_point: Node3D
var displacements: PackedVector3Array

func _ready():
	# Get all displacements from target point to each control point
	for ctrl in ctrl_points:
		displacements.append((ctrl.position - tgt_point.position).normalized())

func _process(delta):
	var rotation := Vector3(0,0,0)
	var activePoints = 0
	for i in range(0, ctrl_points.size()):
		# NOTE: Quaternion Quaternion(arc_from: Vector3, arc_to: Vector3)
		# Constructs a quaternion representing the shortest arc between two points 
		# on the surface of a sphere with a radius of 1.0.
		# So we must keep the radius as 1, meaning we must normalize all position input to quat
		var rot := Quaternion(displacements[i], (ctrl_points[i].position - tgt_point.position).normalized())
		var angle = rot.get_angle()
		if angle != 0:
			print(angle)
		var axis = rot.get_axis()
		rotation += axis.normalized()*angle
		activePoints+=1
	rotation /= activePoints
	tgt_point.rotation = rotation
	
