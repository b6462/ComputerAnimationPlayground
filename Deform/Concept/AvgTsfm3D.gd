extends Node3D

var dragging = false
var drag_target: RigidBody3D = null
var original_mouse_pos := Vector2(0, 0)
@onready var camera = $Camera3D

func _ready():
	var tmp = $RigidBody3D
	print(tmp.position)

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
	if dragging and drag_target:
		print(drag_target)
		var current_mouse_pos = get_viewport().get_mouse_position()
		var delta_pos = current_mouse_pos - original_mouse_pos
		delta_pos *= 0.3
		drag_target.global_position += Vector3(delta_pos.x, -delta_pos.y, 0)*delta
		original_mouse_pos = current_mouse_pos
		
		
