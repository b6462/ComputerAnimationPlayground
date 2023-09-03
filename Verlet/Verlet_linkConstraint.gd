extends Node
class_name VerletConstLink
var VerletObject = preload("res://Verlet/Verlet_object.gd")

var obj_1: VerletObject
var obj_2: VerletObject
var target_dist = 20

func _apply() -> void:
	var axis: Vector2 = obj_1.position_cur - obj_2.position_cur
	var dist = axis.length()
	var n = axis / dist
	var delta = target_dist - dist
	obj_1.position_cur += 0.5 * delta * n
	obj_2.position_cur -= 0.5 * delta * n

