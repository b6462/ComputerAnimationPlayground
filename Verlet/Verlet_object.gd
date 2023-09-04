extends Node
class_name VerletObject

var position_cur := Vector2(200,200)
var position_old := Vector2(200,200)
var acc := Vector2(0,0)
var rad := 20
var stationary := false
var vel := Vector2(0,0)

# Snow flake damping
var damping_ratio := 0.5

# TODO: Add velocity damping according to inertia
var weight = 10

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func updatePosition(dt) -> void:
	if not stationary:
		# Add damping to velocity update
		damping_ratio = lerp(0.8, 1.0, rad/30)
		vel = lerp(vel, position_cur - position_old, damping_ratio)
		vel = position_cur - position_old
		position_old = position_cur
		
		# Add damping to position update
		damping_ratio = lerp(0.99, 1.0, rad/30)
		position_cur = lerp(position_cur, position_cur + vel + acc * dt * dt, damping_ratio)
		#position_cur = position_cur + vel + acc * dt * dt
		acc = Vector2(0,0)
	else:
		position_cur = position_old
	
func accelerate(acc_new: Vector2) -> void:
	acc += acc_new
	

