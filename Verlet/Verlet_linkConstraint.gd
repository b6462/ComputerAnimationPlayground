extends Node
class_name VerletConstLink
var VerletObject = preload("res://Verlet/Verlet_object.gd")

var obj_1: VerletObject
var obj_2: VerletObject

# Gap between verlet objects
var gap = 5

# Soft - hard link
var fix_force = 0.1 # 0.0001 <-> 0.5

func _apply() -> void:
	var axis: Vector2 = obj_1.position_cur - obj_2.position_cur
	var dist = axis.length()
	var n = axis / dist
	var delta = obj_1.rad + obj_2.rad + gap - dist
	obj_1.position_cur += fix_force * delta * n
	obj_2.position_cur -= fix_force * delta * n

