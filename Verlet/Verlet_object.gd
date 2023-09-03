extends Node
class_name VerletObject

var position_cur := Vector2(200,200)
var position_old := Vector2(200,200)
var acc := Vector2(0,0)
var rad := 20
var stationary = false

# TODO: Add velocity damping according to inertia
var weight = 10

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func updatePosition(dt) -> void:
	if not stationary:
		var velocity := position_cur - position_old
		position_old = position_cur
		position_cur = position_cur + velocity + acc * dt * dt
		acc = Vector2(0,0)
	else:
		position_cur = position_old
	
func accelerate(acc_new: Vector2) -> void:
	acc += acc_new
	

