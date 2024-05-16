extends ColorRect

@onready var rayMarchScreen = $"."
@onready var mat = rayMarchScreen.material as ShaderMaterial

var cameraPosition = Vector3(0.0,1.0,-5.0);
var cameraRotation =  Vector3(0.0,0.0,0.0);

var cameraVelocity = Vector3(0.0,0.0,0.0);
var cameraRotationVelocity = Vector3(0.0,0.0,0.0);

var fieldOfView = 0.0;
var fovMax = 10.0;

var drag = 0.9;
var turnSpeed = 0.3;
var walkSpeed = 0.5;
var runSpeed = 2.0;

var RAD = deg_to_rad(90.0);

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var movementSpeed;
	if Input.is_action_pressed("Run"):
		movementSpeed = runSpeed;
	else:
		movementSpeed = walkSpeed;
	# Camera Position
	if Input.is_action_pressed("Forward"):
		cameraVelocity.x += movementSpeed*sin(cameraRotation.x)*delta;
		cameraVelocity.z += movementSpeed*cos(cameraRotation.x)*delta;
	if Input.is_action_pressed("Backward"):
		cameraVelocity.x -= movementSpeed*sin(cameraRotation.x)*delta;
		cameraVelocity.z -= movementSpeed*cos(cameraRotation.x)*delta;
	if Input.is_action_pressed("Left"):
		cameraVelocity.x += movementSpeed*sin(cameraRotation.x-RAD)*delta;
		cameraVelocity.z += movementSpeed*cos(cameraRotation.x-RAD)*delta;
	if Input.is_action_pressed("Right"):
		cameraVelocity.x += movementSpeed*sin(cameraRotation.x+RAD)*delta;
		cameraVelocity.z += movementSpeed*cos(cameraRotation.x+RAD)*delta;
	if Input.is_action_pressed("Up"):
		cameraVelocity.y += movementSpeed*delta;
	if Input.is_action_pressed("Down"):
		cameraVelocity.y -= movementSpeed*delta;
	
	# Viewing Direction
	if Input.is_action_pressed("LookUp"):
		cameraRotationVelocity.y -= turnSpeed*delta;
	if Input.is_action_pressed("LookDown"):
		cameraRotationVelocity.y += turnSpeed*delta;
	if Input.is_action_pressed("LookLeft"):
		cameraRotationVelocity.x -= turnSpeed*delta;
	if Input.is_action_pressed("LookRight"):
		cameraRotationVelocity.x += turnSpeed*delta;
	
	# Camera Zoom
	if Input.is_action_just_released("ZoomIn"):
		fieldOfView += 10.0*delta;
	if Input.is_action_just_released("ZoomOut"):
		fieldOfView -= 10.0*delta;
	
	# Apply Drag
	cameraVelocity *= drag;
	cameraRotationVelocity *= drag;
	
	# Add velocity onto current info
	cameraPosition += cameraVelocity;
	cameraRotation += cameraRotationVelocity;
	
	# Limit
	if (cameraRotation.y > RAD):
		cameraRotation.y = RAD;
	if (cameraRotation.y < -RAD):
		cameraRotation.y = -RAD;
	
	if (fieldOfView < 0.0):
		fieldOfView = 0.0;
	if (fieldOfView > fovMax):
		fieldOfView = fovMax;
	
	# Apply to shader
	mat.set("shader_parameter/cameraPosition", cameraPosition);
	mat.set("shader_parameter/cameraRotation", cameraRotation);
	mat.set("shader_parameter/fieldOfView", fieldOfView);
