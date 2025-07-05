extends Node3D

@onready var rayMarchScreen = $Camera3D/CanvasLayer/ColorRect
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

var maxBounces = 0;
var numberOfSamples = 1;

var nodes : Array = []

func get_all_children(node) -> Array:
	var nodes : Array = []
	for N in node.get_children():
		#if N.get_child_count() > 0:
		#	nodes.append(N)
		#	nodes.append_array(get_all_children(N))
		#else:
		nodes.append(N)
	return nodes

func packObject(object):
	var data = [];
	var type;
	var id = object.get_instance_id();
	var pos = object.get_position();
	var rot = object.get_rotation();
	var scl = object.get_scale();
	var param;
	var objectType = object.get_mesh();
	if (objectType is SphereMesh):
		type = 1;
		param = objectType.get_radius();
	if (objectType is BoxMesh):
		type = 2;
	if (objectType is TorusMesh):
		type = 3;
		param = Vector2(objectType.get_inner_radius(), objectType.get_outer_radius());
	data.append(type)
	data.append(id)
	data.append(pos)
	data.append(rot)
	data.append(scl)
	data.append(param)
	return data;

# Called when the node enters the scene tree for the first time.
func _ready():
	# TODO: Data transfer via 1D Texture to shader??
	# Send current level data
	# TODO: Make it so this only runs if level was changed
	# TODO: Also make it so this only runs on the objects that changed
	nodes = get_all_children($".")
	var vec3OfNodes = [];
	for i in nodes:
		vec3OfNodes.append(Vector3(i.get_position()));
		if i is MeshInstance3D:
			print(packObject(i))
	mat.set("shader_parameter/maxObjects", nodes.size());
	mat.set("shader_parameter/objects", vec3OfNodes)
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):	
	# Camera Movement
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
		
	if Input.is_action_just_pressed("increaseBounces"):
		maxBounces += 1;
	if Input.is_action_just_pressed("decreaseBounces"):
		maxBounces -= 1;
		
	if (maxBounces < 0):
		maxBounces = 0;
		
	if Input.is_action_just_pressed("increaseSamples"):
		numberOfSamples += 1;
	if Input.is_action_just_pressed("decreaseSamples"):
		numberOfSamples -= 1;
	if (numberOfSamples < 1):
		numberOfSamples = 1;
	
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
	mat.set("shader_parameter/maxBounces", maxBounces);
	mat.set("shader_parameter/numberOfSamples", numberOfSamples);
