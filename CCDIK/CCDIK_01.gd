extends Node2D
# CCDIK

const ITERATIONS = 32

var base_point := Vector2(640, 360)
var joints = [
	[80, 0],
	[60, 0],
	[60, 0],
	[80, 0]
]

func _ready():
	pass

func get_joint_pos(idx: int) -> Vector2:
	if idx == 0:
		return base_point
	else:
		var pos_buf := base_point
		for i in range(0, idx):
			pos_buf = pos_buf + Vector2(joints[i][0], 0).rotated(joints[i][1])
		return pos_buf

func update_ik(target: Vector2) -> void:
	for i in range(0, ITERATIONS):
		_backward_pass(target)
		
func _backward_pass(target: Vector2) -> void:
	for i in range(joints.size()-1, -1, -1):
		var e_dir: Vector2 = get_joint_pos(joints.size()) - get_joint_pos(i)
		var t_dir: Vector2 = target - get_joint_pos(i)
		var angle = e_dir.angle_to(t_dir)
		joints[i][1] += angle
		
func _process(delta):
	update_ik(get_global_mouse_position())
	queue_redraw()

func _draw() -> void:
	var pre_pos: Vector2 = base_point
	for j in joints:
		var new_pos := pre_pos + Vector2(j[0], 0).rotated(j[1])
		draw_line(pre_pos, new_pos, Color.GRAY, 3)
		pre_pos = new_pos
		
	draw_circle(base_point, 5, Color.WHITE)
	pre_pos = base_point
	for j in joints:
		var new_pos := pre_pos + Vector2(j[0], 0).rotated(j[1])
		draw_circle(new_pos, 5, Color.WHITE)
		pre_pos = new_pos
		
