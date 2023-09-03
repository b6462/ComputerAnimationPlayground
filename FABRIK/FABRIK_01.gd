extends Node2D

const ITERATIONS = 32

var base_point = Vector2(140, 135)
var limbs = [
	80,
	60,
	80
]

var joints = PackedVector2Array()
var limbs_size = 0
var limbs_len = 0

@onready var info = $Label
var all_iteration = 0
var iterations_count = 0

func _ready():
	limbs_size = limbs.size()
	joints.resize(limbs_size + 1)
	joints[0] = base_point
	for i in range(limbs_size):
		limbs_len += limbs[i]
		# Initialize horizontal joint chain
		joints[i+1] = joints[i] + Vector2(limbs[i], 0)

func update_ik(target: Vector2) -> void:
	# OPTIMIZATION_01: Far distance optmiz
	var dist = base_point.distance_squared_to(target)
	# VISUALIZATION_01: Iter benchmark
	var iterations = 0
	
	# Iterate only once if over stretch
	if dist > limbs_len*limbs_len:
		_backward_pass(target)
		_forward_pass()
		iterations = 1
	else:
		# OPTIMIZATION_02: Mid Iteration optmiz
		var min_dist = INF
		var min_joints = PackedVector2Array()
		while iterations < ITERATIONS:
			_backward_pass(target)
			_forward_pass()
			iterations += 1
			
			# For each iteration, check if target is already reached
			# Get distance of target joint to target
			dist = joints[limbs_size].distance_squared_to(target)
			if min_dist > dist:
				min_dist = dist
				# Save current state
				min_joints = joints.duplicate()
			else:
				# if distance is minimal, break iteration
				break
				
		# Set to break state incase joints moved
		if dist > min_dist:
			joints = min_joints
	
	all_iteration += iterations
	iterations_count+=1
	info.text = "Iteration average: " + str(all_iteration / iterations_count)
		
func _backward_pass(target: Vector2) -> void:
	joints[limbs_size] = target;
	for i in range(limbs_size, 0, -1):
		var a = joints[i]
		var b = joints[i-1]
		var angle = a.angle_to_point(b)
		joints[i-1] = a + Vector2(limbs[i-1], 0).rotated(angle)
		
func _forward_pass() -> void:
	joints[0] = base_point
	for i in range(limbs_size):
		var a = joints[i]
		var b = joints[i+1]
		var angle = a.angle_to_point(b)
		joints[i+1] = a + Vector2(limbs[i], 0).rotated(angle)

func _process(delta):
	update_ik(get_global_mouse_position())
	queue_redraw()

func _draw() -> void:
	for i in range(limbs_size+1):
		if i > 0:
			draw_line(joints[i-1], joints[i], Color.WEB_GRAY)
			
	for i in range(limbs_size+1):
		draw_circle(joints[i], 2, Color.WHITE)
