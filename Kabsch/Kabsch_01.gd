extends Node

@export var movPoints: Array[Node3D]
@export var refPoints: Array[Node3D]
var movPointsPos: PackedVector3Array
var refPointsPos: PackedVector3Array

var kabsch_solver := preload("res://Kabsch/Kabsch_Solver.gd")
var solver := KabschSolver.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	for pt in movPoints:
		movPointsPos.append(pt.position)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	for rpt in refPoints:
		refPointsPos.append(rpt.position)
		
	var solve_transform := solver.SolveKabsch(movPoints, refPoints)
	print(solve_transform)
