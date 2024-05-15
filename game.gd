extends Node2D

@onready var rayMarchScreen = $Camera2D/CanvasLayer/ColorRect

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	rayMarchScreen.material.get_shader_param("shader_parameter/cameraAngle");
	pass
