extends ColorRect

@onready var rayMarchScreen = $"."
@onready var mat = rayMarchScreen.material as ShaderMaterial

var cameraPosition = Vector3(0.0,0.0,-5.0);
var cameraAngle = 0.0;

var cameraVelocity = Vector3(0.0,0.0,0.0);
var cameraAngleVelocity = 0.0;

var drag = 0.9;
var turnSpeed = 0.3;
var movementSpeed = 0.5;

var RAD = deg_to_rad(90.0);

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	mat.set("shader_parameter/cameraAngle", cameraAngle);
	mat.set("shader_parameter/cameraPosition", cameraPosition);
	
	if Input.is_action_pressed("Forward"):
		cameraVelocity.x += movementSpeed*sin(cameraAngle)*delta;
		cameraVelocity.z += movementSpeed*cos(cameraAngle)*delta;
	if Input.is_action_pressed("Backward"):
		cameraVelocity.x -= movementSpeed*sin(cameraAngle)*delta;
		cameraVelocity.z -= movementSpeed*cos(cameraAngle)*delta;
	if Input.is_action_pressed("Left"):
		cameraVelocity.x += movementSpeed*sin(cameraAngle-RAD)*delta;
		cameraVelocity.z += movementSpeed*cos(cameraAngle-RAD)*delta;
	if Input.is_action_pressed("Right"):
		cameraVelocity.x += movementSpeed*sin(cameraAngle+RAD)*delta;
		cameraVelocity.z += movementSpeed*cos(cameraAngle+RAD)*delta;
	if Input.is_action_pressed("Up"):
		cameraVelocity.y += movementSpeed*delta;
	if Input.is_action_pressed("Down"):
		cameraVelocity.y -= movementSpeed*delta;
	if Input.is_action_pressed("TurnLeft"):
		cameraAngleVelocity -= turnSpeed*delta;
	if Input.is_action_pressed("TurnRight"):
		cameraAngleVelocity += turnSpeed*delta;
		
	cameraAngleVelocity *= drag;
	cameraVelocity *= drag;
	cameraPosition += cameraVelocity;
	cameraAngle += cameraAngleVelocity;
