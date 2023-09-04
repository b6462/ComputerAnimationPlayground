extends Node2D
# From https://www.youtube.com/watch?v=lS_qeBy3aQI&ab_channel=Pezzza%27sWork
# C++ -> gd script
# This script shows the basic concept of a verlet object
# Including a link-constrained bridge in the center and objects spawning at clicked position
var VerletObject = preload("res://Verlet/Verlet_object.gd")
var update_list: Array[VerletObject] = []

var VerletLink = preload("res://Verlet/Verlet_linkConstraint.gd")
var constLink_list: Array[VerletConstLink] = []

# World parameters
var gravity: Vector2 = Vector2(0, 1000)
var rng = RandomNumberGenerator.new()

# Constraints
const imagineCenter = Vector2(640, 360)
const imagineRadius = 300

func _ready():
	# Create a linked rope bridge in the middle
	var link_rad = 10
	var len = 25
	for i in range(0, len+1):
		var new_obj = VerletObject.new()
		new_obj.rad = link_rad
		new_obj.position_cur = Vector2(640-(len*link_rad) + i*link_rad*2, 360)
		new_obj.position_old = Vector2(640-(len*link_rad) + i*link_rad*2, 360)
		if i == 0 or i == len:
			new_obj.stationary = true
		update_list.append(new_obj)
		
		# Link up
		if i != 0:
			var new_link = VerletConstLink.new()
			new_link.obj_1 = update_list[i-1]
			new_link.obj_2 = update_list[i]
			constLink_list.append(new_link)
	
func _input(event):
	# generate new objet at mouse click position with random size
	if event is InputEventMouseButton and event.is_pressed():
		print(event.position)
		var new_obj = VerletObject.new()
		new_obj.rad = rng.randf_range(10, 30)
		new_obj.position_cur = event.position
		new_obj.position_old = event.position
		update_list.append(new_obj)

func _process(delta):
	# Sub-stepping for better result
	var sub_steps = 8
	var sub_dt = delta / sub_steps
	for t in range(0, sub_steps):
		_applyGravity()
		_applyConstraint()
		_solveCollisions()
		_updatePosition(sub_dt)
	queue_redraw()
		
func _draw() -> void:
	# Draw scene bound circle
	draw_circle(imagineCenter, imagineRadius, Color.BLACK)
	
	# Draw verlet objects
	for v_obj in update_list:
		draw_circle(v_obj.position_cur, v_obj.rad, Color.WHITE)
		
	# Draw link constraint lines
	for v_link in constLink_list:
		draw_line(v_link.obj_1.position_cur, v_link.obj_2.position_cur, Color.WHITE, 2)
	
func _applyGravity() -> void:
	for v_obj in update_list:
		v_obj.accelerate(gravity)
	
func _updatePosition(dt) -> void:
	for v_obj in update_list:
		v_obj.updatePosition(dt)

func _applyConstraint() -> void:
	for v_obj in update_list:
		var to_obj = v_obj.position_cur - imagineCenter
		var dist = to_obj.length()
		to_obj = to_obj.normalized()
		if (dist > imagineRadius-v_obj.rad):
			v_obj.position_cur = imagineCenter + to_obj * (imagineRadius - v_obj.rad)
	for l_const in constLink_list:
		l_const._apply()

func _solveCollisions() -> void:
	var object_count = update_list.size()
	for i in range(0, object_count):
		var obj_1: VerletObject = update_list[i]
		for j in range(i + 1, object_count):
			var obj_2: VerletObject = update_list[j]
			var collision_axis: Vector2 = obj_1.position_cur - obj_2.position_cur
			var dist = collision_axis.length()
			if (dist < obj_1.rad + obj_2.rad):
				var n: Vector2 = collision_axis / dist
				var delta = obj_1.rad + obj_2.rad - dist
				obj_1.position_cur += 0.5 * delta * n
				obj_2.position_cur -= 0.5 * delta * n
		
