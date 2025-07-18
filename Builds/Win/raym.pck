GDPC                P                                                                      
   T   res://.godot/exported/133200997/export-14584830dbc22d3f76a596eed5f4948e-node_3d.scn P      }	      ��������Y�A�    ,   res://.godot/global_script_class_cache.cfg  �M             ��Р�8���8~$}P�    D   res://.godot/imported/icon.svg-218a8f2b3041327d8a5756f3a245f83b.ctex`            ：Qt�E�cO���       res://.godot/uid_cache.bin  �Q      <       ���UԔp�l_���       res://game.gd           Z      ���d��c��T�@1�1       res://icon.svg  �M      �      k����X3Y���f       res://icon.svg.import   �      �       �=������O�Z��A�       res://node_3d.tscn.remapPM      d       �k�	���c{oo�       res://project.binary�Q      8!      ϯ��1�C�[�w@��{       res://raymarch.gdshader �'      �%      N&�}/�g���    extends Node3D

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
      GST2   �   �      ����               � �        �  RIFF�  WEBPVP8L�  /������!"2�H�m�m۬�}�p,��5xi�d�M���)3��$�V������3���$G�$2#�Z��v{Z�lێ=W�~� �����d�vF���h���ڋ��F����1��ڶ�i�엵���bVff3/���Vff���Ҿ%���qd���m�J�}����t�"<�,���`B �m���]ILb�����Cp�F�D�=���c*��XA6���$
2#�E.@$���A.T�p )��#L��;Ev9	Б )��D)�f(qA�r�3A�,#ѐA6��npy:<ƨ�Ӱ����dK���|��m�v�N�>��n�e�(�	>����ٍ!x��y�:��9��4�C���#�Ka���9�i]9m��h�{Bb�k@�t��:s����¼@>&�r� ��w�GA����ը>�l�;��:�
�wT���]�i]zݥ~@o��>l�|�2�Ż}�:�S�;5�-�¸ߥW�vi�OA�x��Wwk�f��{�+�h�i�
4�˰^91��z�8�(��yޔ7֛�;0����^en2�2i�s�)3�E�f��Lt�YZ���f-�[u2}��^q����P��r��v��
�Dd��ݷ@��&���F2�%�XZ!�5�.s�:�!�Њ�Ǝ��(��e!m��E$IQ�=VX'�E1oܪì�v��47�Fы�K챂D�Z�#[1-�7�Js��!�W.3׹p���R�R�Ctb������y��lT ��Z�4�729f�Ј)w��T0Ĕ�ix�\�b�9�<%�#Ɩs�Z�O�mjX �qZ0W����E�Y�ڨD!�$G�v����BJ�f|pq8��5�g�o��9�l�?���Q˝+U�	>�7�K��z�t����n�H�+��FbQ9���3g-UCv���-�n�*���E��A�҂
�Dʶ� ��WA�d�j��+�5�Ȓ���"���n�U��^�����$G��WX+\^�"�h.���M�3�e.
����MX�K,�Jfѕ*N�^�o2��:ՙ�#o�e.
��p�"<W22ENd�4B�V4x0=حZ�y����\^�J��dg��_4�oW�d�ĭ:Q��7c�ڡ��
A>��E�q�e-��2�=Ϲkh���*���jh�?4�QK��y@'�����zu;<-��|�����Y٠m|�+ۡII+^���L5j+�QK]����I �y��[�����(}�*>+���$��A3�EPg�K{��_;�v�K@���U��� gO��g��F� ���gW� �#J$��U~��-��u���������N�@���2@1��Vs���Ŷ`����Dd$R�":$ x��@�t���+D�}� \F�|��h��>�B�����B#�*6��  ��:���< ���=�P!���G@0��a��N�D�'hX�׀ "5#�l"j߸��n������w@ K�@A3�c s`\���J2�@#�_ 8�����I1�&��EN � 3T�����MEp9N�@�B���?ϓb�C��� � ��+�����N-s�M�  ��k���yA 7 �%@��&��c��� �4�{� � �����"(�ԗ�� �t�!"��TJN�2�O~� fB�R3?�������`��@�f!zD��%|��Z��ʈX��Ǐ�^�b��#5� }ى`�u�S6�F�"'U�JB/!5�>ԫ�������/��;	��O�!z����@�/�'�F�D"#��h�a �׆\-������ Xf  @ �q�`��鎊��M��T�� ���0���}�x^�����.�s�l�>�.�O��J�d/F�ě|+^�3�BS����>2S����L�2ޣm�=�Έ���[��6>���TъÞ.<m�3^iжC���D5�抺�����wO"F�Qv�ږ�Po͕ʾ��"��B��כS�p�
��E1e�������*c�������v���%'ž��&=�Y�ް>1�/E������}�_��#��|������ФT7׉����u������>����0����緗?47�j�b^�7�ě�5�7�����|t�H�Ե�1#�~��>�̮�|/y�,ol�|o.��QJ rmϘO���:��n�ϯ�1�Z��ը�u9�A������Yg��a�\���x���l���(����L��a��q��%`�O6~1�9���d�O{�Vd��	��r\�՜Yd$�,�P'�~�|Z!�v{�N�`���T����3?DwD��X3l �����*����7l�h����	;�ߚ�;h���i�0�6	>��-�/�&}% %��8���=+��N�1�Ye��宠p�kb_����$P�i�5�]��:��Wb�����������ě|��[3l����`��# -���KQ�W�O��eǛ�"�7�Ƭ�љ�WZ�:|���є9�Y5�m7�����o������F^ߋ������������������Р��Ze�>�������������?H^����&=����~�?ڭ�>���Np�3��~���J�5jk�5!ˀ�"�aM��Z%�-,�QU⃳����m����:�#��������<�o�����ۇ���ˇ/�u�S9��������ٲG}��?~<�]��?>��u��9��_7=}�����~����jN���2�%>�K�C�T���"������Ģ~$�Cc�J�I�s�? wڻU���ə��KJ7����+U%��$x�6
�$0�T����E45������G���U7�3��Z��󴘶�L�������^	dW{q����d�lQ-��u.�:{�������Q��_'�X*�e�:�7��.1�#���(� �k����E�Q��=�	�:e[����u��	�*�PF%*"+B��QKc˪�:Y��ـĘ��ʴ�b�1�������\w����n���l镲��l��i#����!WĶ��L}rեm|�{�\�<mۇ�B�HQ���m�����x�a�j9.�cRD�@��fi9O�.e�@�+�4�<�������v4�[���#bD�j��W����֢4�[>.�c�1-�R�����N�v��[�O�>��v�e�66$����P
�HQ��9���r�	5FO� �<���1f����kH���e�;����ˆB�1C���j@��qdK|
����4ŧ�f�Q��+�     [remap]

importer="texture"
type="CompressedTexture2D"
uid="uid://bhtcmvrqbah7g"
path="res://.godot/imported/icon.svg-218a8f2b3041327d8a5756f3a245f83b.ctex"
metadata={
"vram_texture": false
}
                RSRC                    PackedScene            ��������                                                  ..    MeshInstance3D    resource_local_to_scene    resource_name    shader #   shader_parameter/antiAliasingLevel     shader_parameter/cameraPosition     shader_parameter/cameraRotation    shader_parameter/cameraOffset    shader_parameter/fieldOfView    shader_parameter/bgGradient    shader_parameter/bg1    shader_parameter/bg2    shader_parameter/skyboxAxis    shader_parameter/skyboxAngle    shader_parameter/voidColor    shader_parameter/sizeOfData    shader_parameter/maxObjects    shader_parameter/objects    script    lightmap_size_hint 	   material    custom_aabb    flip_faces    add_uv2    uv2_padding    inner_radius    outer_radius    rings    ring_segments 	   _bundled       Script    res://game.gd ��������   Shader    res://raymarch.gdshader ��������      local://ShaderMaterial_mwhae          local://TorusMesh_dgm0u          local://PackedScene_r0c7d =         ShaderMaterial                                      �?  ��                     
           	          
   )   ���(\��?      �̌>�z>�z�>      ff�?R�~?   ?      333?           )   ��H.�!��      =
?�G?�E?                d      #             
   TorusMesh          ���>         PackedScene          	         names "         Node3D    script 	   Camera3D 
   transform 	   v_offset    fov    size    CanvasLayer 
   ColorRect 	   material    anchors_preset    anchor_right    anchor_bottom    metadata/_edit_use_anchors_    MeshInstance3D    mesh    MeshInstance3D2 	   skeleton    	   variants                      �?              �?              �?      �?�q@     ��     �B   )\�=                     �?           �?              �?              �?f�o����49}ž              �?              �?              �?0�^?�O&?ƢM�                   node_count             nodes     H   ��������        ����                            ����                                            ����                     ����   	      
                                          ����      	      
                     ����            
                   conn_count              conns               node_paths              editable_instances              version             RSRC   shader_type canvas_item;
render_mode unshaded;

uniform int antiAliasingLevel = 0;
uniform vec3 cameraPosition = vec3(0.0f,1.0f,-5.0f);
uniform vec3 cameraRotation = vec3(0.0f,0.0f,0.0f);
uniform vec2 cameraOffset = vec2(0.0f,0.0f);
uniform float fieldOfView = 0.0f;
uniform float bgGradient = 4.93;
uniform vec3 bg1 = vec3(0.275,0.145,0.415);
uniform vec3 bg2 = vec3(1.425,0.995,0.5);
uniform vec3 skyboxAxis = vec3(0.7,0.0,0.0);
uniform float skyboxAngle = -1.570796;
uniform vec3 voidColor = vec3(0.59,0.505,0.77);

struct Object {
  vec3 position;
  vec3 rotation;
  float scale;
};

uniform int sizeOfData = 0;


uniform int maxObjects = 100;
uniform vec3[100] objects;

void vertex() {
	// Called for every vertex the material is visible on.
}

vec3 rot3D(vec3 p, vec3 axis, float angle) {
	axis = normalize(axis);
	return mix(dot(axis,p) * axis, p, cos(angle)) + cross(axis,p) * sin(angle);
}

vec3 rotFromEuler(vec3 p, vec3 eulerAngles) {
  // Extract pitch, yaw, and roll from eulerAngles
  float pitch = eulerAngles.x;
  float yaw = eulerAngles.y;
  float roll = eulerAngles.z;

  // Calculate rotation axis based on pitch, yaw, and roll
  vec3 axis = normalize(vec3(sin(yaw) * cos(pitch), cos(yaw) * cos(pitch), sin(pitch)));

  // Use rot3D with the calculated axis and angle for each rotation
  return rot3D(rot3D(rot3D(p, axis, roll), vec3(1.0, 0.0, 0.0), yaw), vec3(0.0, 1.0, 0.0), pitch);
}

float sdfSphere(vec3 position, vec3 sphereOrigin, float radius) {
    return distance(position, sphereOrigin) - radius;
}

float sdfPlane(vec3 position, vec4 plane) {
    // Plane equation: plane.x * x + plane.y * y + plane.z * z + plane.w = 0
    // plane = (A, B, C, D) where (A, B, C) is the plane normal, and D is the plane constant
    vec3 planeXyz = vec3(plane.x, plane.y, plane.z);
    return dot(planeXyz, position) + plane.w;
}

float sdfWavePlane(vec3 position, vec4 plane, float frequency, float amplitude, vec2 direction) {
	// Plane equation: plane.x * x + plane.y * y + plane.z * z + plane.w = 0
	// plane = (A, B, C, D) where (A, B, C) is the plane normal, and D is the plane constant
	vec3 planeXyz = vec3(plane.x, plane.y, plane.z);
	float basePlaneDistance = dot(planeXyz, position) + plane.w;
	// Calculate the wave offset based on position
	float waveOffset = sin(frequency * (position.x + (direction.x * TIME))) * amplitude;
	waveOffset *= cos(frequency * (position.z + (direction.y * TIME))) * amplitude ;
	return basePlaneDistance + waveOffset;
}

/* Compute distance to a gyroid */
float sdfGyroid(vec3 p, float k) {
	p = p * k + TIME;
	return sin(p.x) * cos(p.y) + sin(p.y) * cos(p.z) + sin(p.z) * cos(p.x);
}

float sdBox( vec3 p, vec3 b, vec3 position, vec3 rotationAxis, float angle) {
	p -= position;
	p = rot3D(p,rotationAxis,angle);
	vec3 q = abs(p) - b;
	return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdPyramid( vec3 p, float h, float scale, vec3 position, vec3 rotationAxis, float angle) {
	p -= position;
	p = rot3D(p,rotationAxis,angle);
	p /= scale;
	float m2 = h*h + 0.25;

	p.xz = abs(p.xz);
	p.xz = (p.z>p.x) ? p.zx : p.xz;
	p.xz -= 0.5;

	vec3 q = vec3( p.z, h*p.y - 0.5*p.x, h*p.x + 0.5*p.y);

	float s = max(-q.x,0.0);
	float t = clamp( (q.y-0.5*p.z)/(m2+0.25), 0.0, 1.0 );

	float a = m2*(q.x+s)*(q.x+s) + q.y*q.y;
	float b = m2*(q.x+0.5*t)*(q.x+0.5*t) + (q.y-m2*t)*(q.y-m2*t);

	float d2 = min(q.y,-q.x*m2-q.y*0.5) > 0.0 ? 0.0 : min(a,b);

	return (sqrt( (d2+q.z*q.z)/m2 ) * sign(max(q.z,-p.y)))*scale;
}

float sdTorus( vec3 p, vec3 position, vec2 t )
{
	p -= position;
	vec2 q = vec2(length(p.xz)-t.x,p.y);
	return length(q)-t.y;
}

float opUnion( float d1, float d2 )
{
    return min(d1,d2);
}
float opSubtraction( float d1, float d2 )
{
    return max(-d1,d2);
}
float opIntersection( float d1, float d2 )
{
    return max(d1,d2);
}
float opXor(float d1, float d2 )
{
    return max(min(d1,d2),-max(d1,d2));
}

float opSmoothUnion( float d1, float d2, float k )
{
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h);
}

float opSmoothSubtraction( float d1, float d2, float k )
{
    float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    return mix( d2, -d1, h ) + k*h*(1.0-h);
}

float opSmoothIntersection( float d1, float d2, float k )
{
    float h = clamp( 0.5 - 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) + k*h*(1.0-h);
}

/*
float mapTheWorld(vec3 p) {
	float finalDistance = 1000000000000.0;
	for (int i = 0; i < maxObjects; i++) {
		finalDistance = min(sdTorus(p, objects[i], vec2(1.0,0.4)), finalDistance);
	}
	return finalDistance;
}*/

float mapTheWorld(vec3 p)
{
    float value = sin(TIME/5.0f);
    float value2 = cos(TIME/5.0f)/20.0;
    float value3 = sin(TIME/2.0f);
    float value4 = cos(TIME/2.0f);
    vec3 circle = vec3(3.0f+value,0.0f+value3,-2.0f+value2 );
    float sphere_1 = sdfSphere(p, circle, 1.0);
    vec3 circle2 = vec3(3.5f, 0.5f, -2.0f);
    float sphere_2 = sdfSphere(p, circle2, 1.0);
    vec3 circle3 = vec3(-2.5f, -0.5f+value4, -1.0f);
    float sphere_3 = sdfSphere(p, circle3, 1.5);
	vec4 plane2 = vec4(0.0, 1.0, 0.0,0.5);
    float plane_5 = sdfWavePlane(p, plane2, 1.0, 0.5*sin(TIME), vec2(1.0,1.0));
    float plane_6 = sdfWavePlane(p, plane2, 1.211, 0.25*cos(TIME), vec2(1.0,1.0));
	vec3 boxSize = vec3(4.0,1.0,2.0);
	vec3 boxPos = vec3(-10.0,3.0,5);
	float box_7 = sdBox(p, boxSize, boxPos, vec3(0.0,1.0,0.0), TIME/3.0);
	float torus_8 = sdTorus(p, vec3(0.0), vec2(1.0,0.4));
	float torus_9 = sdTorus(p, vec3(0.0), vec2(1.0,0.5));
	float plane_7 = sdfWavePlane(p, vec4(0.0,1.0,0.0, 0.0), 10.0, 0.3, vec2(0.0,0.0));
	float pyramid_8 = sdPyramid(p, 1.0, 5.0, vec3(10.0), vec3(0.0,1.0,0.0), -TIME/5.0);
	float pryamidFrequency = 1.0;
	float pyramidAmplitude = 1.0;
	float waveOffset = sin(pryamidFrequency * (p.x + TIME)) * pyramidAmplitude;
	waveOffset *= cos(pryamidFrequency * (p.z + TIME)) * pyramidAmplitude;
	float pyramid_10 = sdPyramid(p, 1.0, -50.0, vec3(0.0, 20.0, 0.0), vec3(0.0,1.0,0.0), -TIME/5.0)+waveOffset;
	float pyramid_9 = sdPyramid(p, 1.0, 3.0+sin(TIME), vec3(-10.0, 4.0, 5.0), vec3(1.0,1.0,1.0), -TIME/3.0);
	
    // max for itersection
    // min for both
    float finalDistance = opIntersection(sphere_1,sphere_2);
	finalDistance = min(opSmoothSubtraction(pyramid_10, opSmoothSubtraction(sphere_3,opSmoothIntersection(plane_6,plane_5, 0.1),0.1), 1.0), finalDistance);
	finalDistance = min(opSmoothUnion(box_7,pyramid_9, 0.5), finalDistance);
	finalDistance = min(torus_8, finalDistance);
	finalDistance = min(opSmoothSubtraction(plane_7, torus_9, 0.1), finalDistance);
	finalDistance = min(pyramid_8, finalDistance);
	
    return finalDistance;
}

vec3 calculateNormal(vec3 p)
{
    vec3 smallStep = vec3(0.001f, 0.0f, 0.0f);

    vec3 smallStepXyy = vec3(smallStep.x,smallStep.y,smallStep.y);
    vec3 smallStepYxy = vec3(smallStep.y,smallStep.x,smallStep.y);
    vec3 smallStepYyx = vec3(smallStep.y,smallStep.y,smallStep.x);

    float gradientX = mapTheWorld(p + smallStepXyy) - mapTheWorld(p - smallStepXyy);
    float gradientY = mapTheWorld(p + smallStepYxy) - mapTheWorld(p - smallStepYxy);
    float gradientZ = mapTheWorld(p + smallStepYyx) - mapTheWorld(p - smallStepYyx);

    vec3 normal = vec3(gradientX,gradientY,gradientZ);

    normal = normalize(normal);

    return normal;
}

vec3 lerp(vec3 a, vec3 b, float t) {
	return a + (b - a) * t;
}

vec3 interpolateColor(vec3 color1, vec3 color2, float transitionSpeed, float factor) {
  return mix(color1, color2, smoothstep(0.0, 1.0, transitionSpeed * factor));
}

vec3 getSkybox(vec3 rayDirection) {
	rayDirection = rot3D(rayDirection, skyboxAxis, skyboxAngle);
	return interpolateColor(bg1,bg2,rayDirection.y,bgGradient);
}

vec3 getGlow(vec3 rayDirection) {
	return getSkybox(rayDirection);
}

vec3 rayMarch(vec3 rayOrigin, vec3 rayDirection) {
	int numberOfSteps = 80;
	float minDistance = 0.001;
	float maxDistance = 100.0;
	float progress = 0.0;
	vec3 color = getSkybox(rayDirection); //vec3(1.0);
	
	for (int i = 0; i < numberOfSteps; ++i) {
		vec3 currentPosition = rayOrigin + rayDirection * progress;
		float distanceToClosest = mapTheWorld(currentPosition);
		progress += distanceToClosest;
		vec3 empty = vec3(float(i))/float(numberOfSteps); 
		color *= (1.0 - empty)*voidColor;
		color += empty * getGlow(rayDirection);
		if (distanceToClosest < minDistance) { break; }
		if (progress >= maxDistance) { return getSkybox(rayDirection); }
	}
	color *= 1.0 - vec3(progress / maxDistance);
	return color;
}

void fragment() {
    // Initial renderer color
	float aspectRatio = SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y;
	vec2 uv = (UV-0.5)*2.0;
	uv.y *= -1.0;
	uv.x = uv.x/aspectRatio;
    vec3 rayDirection = normalize(vec3(uv,1.0f) + vec3(cameraOffset,fieldOfView));
	rayDirection = rotFromEuler(rayDirection, cameraRotation);
	vec3 c;
	
	/*
	if (antiAliasingLevel > 1) {
		float fAAL = float(antiAliasingLevel);
		float aaL = 1.0/fAAL;
		float offset = 1.0/(fAAL*fAAL);
		int numberOfPoints = 0;
		for(float y = -aaL; y <= aaL; y+=offset) {
			for(float x = -aaL; x <= aaL; x+=offset) {
				vec3 offset = vec3(x*SCREEN_PIXEL_SIZE.x,y*SCREEN_PIXEL_SIZE.y, 0.0);
				vec3 newPos = cameraPosition + offset;
				c += rayMarch(newPos, rayDirection);
				numberOfPoints++;
			}
		}
	    c = c/float(numberOfPoints);
	} else {*/
		c = rayMarch(cameraPosition, rayDirection);
	//}
	// Called for every pixel the material is visible on.
	COLOR = vec4(c, 1.0);
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
[remap]

path="res://.godot/exported/133200997/export-14584830dbc22d3f76a596eed5f4948e-node_3d.scn"
            list=Array[Dictionary]([])
     <svg height="128" width="128" xmlns="http://www.w3.org/2000/svg"><rect x="2" y="2" width="124" height="124" rx="14" fill="#363d52" stroke="#212532" stroke-width="4"/><g transform="scale(.101) translate(122 122)"><g fill="#fff"><path d="M105 673v33q407 354 814 0v-33z"/><path d="m105 673 152 14q12 1 15 14l4 67 132 10 8-61q2-11 15-15h162q13 4 15 15l8 61 132-10 4-67q3-13 15-14l152-14V427q30-39 56-81-35-59-83-108-43 20-82 47-40-37-88-64 7-51 8-102-59-28-123-42-26 43-46 89-49-7-98 0-20-46-46-89-64 14-123 42 1 51 8 102-48 27-88 64-39-27-82-47-48 49-83 108 26 42 56 81zm0 33v39c0 276 813 276 814 0v-39l-134 12-5 69q-2 10-14 13l-162 11q-12 0-16-11l-10-65H446l-10 65q-4 11-16 11l-162-11q-12-3-14-13l-5-69z" fill="#478cbf"/><path d="M483 600c0 34 58 34 58 0v-86c0-34-58-34-58 0z"/><circle cx="725" cy="526" r="90"/><circle cx="299" cy="526" r="90"/></g><g fill="#414042"><circle cx="307" cy="532" r="60"/><circle cx="717" cy="532" r="60"/></g></g></svg>
              ��bߧ{(   res://icon.svg�0p��   res://node_3d.tscn    ECFG      application/config/name      	   RayMGoDot      application/run/main_scene         res://node_3d.tscn     application/config/features$   "         4.2    Forward Plus       application/config/icon         res://icon.svg     filesystem/import/fbx/enabled             input/Forwardd              deadzone      ?      events              InputEventKey         resource_local_to_scene           resource_name             device     ����	   window_id             alt_pressed           shift_pressed             ctrl_pressed          meta_pressed          pressed           keycode           physical_keycode   W   	   key_label             unicode    w      echo          script            InputEventJoypadMotion        resource_local_to_scene           resource_name             device     ����   axis      
   axis_value       ��   script         input/Backwardd              deadzone      ?      events              InputEventKey         resource_local_to_scene           resource_name             device     ����	   window_id             alt_pressed           shift_pressed             ctrl_pressed          meta_pressed          pressed           keycode           physical_keycode   S   	   key_label             unicode    s      echo          script            InputEventJoypadMotion        resource_local_to_scene           resource_name             device     ����   axis      
   axis_value       �?   script      
   input/Leftd              deadzone      ?      events              InputEventKey         resource_local_to_scene           resource_name             device     ����	   window_id             alt_pressed           shift_pressed             ctrl_pressed          meta_pressed          pressed           keycode           physical_keycode   A   	   key_label             unicode    a      echo          script            InputEventJoypadMotion        resource_local_to_scene           resource_name             device     ����   axis       
   axis_value       ��   script         input/Rightd              deadzone      ?      events              InputEventKey         resource_local_to_scene           resource_name             device     ����	   window_id             alt_pressed           shift_pressed             ctrl_pressed          meta_pressed          pressed           keycode           physical_keycode   D   	   key_label             unicode    d      echo          script            InputEventJoypadMotion        resource_local_to_scene           resource_name             device     ����   axis       
   axis_value       �?   script         input/Up|              deadzone      ?      events              InputEventKey         resource_local_to_scene           resource_name             device     ����	   window_id             alt_pressed           shift_pressed             ctrl_pressed          meta_pressed          pressed           keycode           physical_keycode       	   key_label             unicode           echo          script            InputEventJoypadButton        resource_local_to_scene           resource_name             device     ����   button_index          pressure          pressed           script      
   input/Down|              deadzone      ?      events              InputEventKey         resource_local_to_scene           resource_name             device     ����	   window_id             alt_pressed           shift_pressed             ctrl_pressed          meta_pressed          pressed           keycode           physical_keycode    @ 	   key_label             unicode           echo          script            InputEventJoypadButton        resource_local_to_scene           resource_name             device     ����   button_index         pressure          pressed           script         input/LookLeftd              deadzone      ?      events              InputEventJoypadMotion        resource_local_to_scene           resource_name             device     ����   axis      
   axis_value       ��   script            InputEventKey         resource_local_to_scene           resource_name             device     ����	   window_id             alt_pressed           shift_pressed             ctrl_pressed          meta_pressed          pressed           keycode           physical_keycode    @ 	   key_label             unicode           echo          script         input/LookRightd              deadzone      ?      events              InputEventJoypadMotion        resource_local_to_scene           resource_name             device     ����   axis      
   axis_value       �?   script            InputEventKey         resource_local_to_scene           resource_name             device     ����	   window_id             alt_pressed           shift_pressed             ctrl_pressed          meta_pressed          pressed           keycode           physical_keycode    @ 	   key_label             unicode           echo          script         input/LookUpd              deadzone      ?      events              InputEventJoypadMotion        resource_local_to_scene           resource_name             device     ����   axis      
   axis_value       ��   script            InputEventKey         resource_local_to_scene           resource_name             device     ����	   window_id             alt_pressed           shift_pressed             ctrl_pressed          meta_pressed          pressed           keycode           physical_keycode    @ 	   key_label             unicode           echo          script         input/LookDownd              deadzone      ?      events              InputEventJoypadMotion        resource_local_to_scene           resource_name             device     ����   axis      
   axis_value       �?   script            InputEventKey         resource_local_to_scene           resource_name             device     ����	   window_id             alt_pressed           shift_pressed             ctrl_pressed          meta_pressed          pressed           keycode           physical_keycode    @ 	   key_label             unicode           echo          script         input/ZoomIn�              deadzone      ?      events              InputEventMouseButton         resource_local_to_scene           resource_name             device     ����	   window_id             alt_pressed           shift_pressed             ctrl_pressed          meta_pressed          button_mask           position              global_position               factor       �?   button_index         canceled          pressed           double_click          script         input/ZoomOut�              deadzone      ?      events              InputEventMouseButton         resource_local_to_scene           resource_name             device     ����	   window_id             alt_pressed           shift_pressed             ctrl_pressed          meta_pressed          button_mask           position              global_position               factor       �?   button_index         canceled          pressed           double_click          script      	   input/Run|              deadzone      ?      events              InputEventKey         resource_local_to_scene           resource_name             device     ����	   window_id             alt_pressed           shift_pressed             ctrl_pressed          meta_pressed          pressed           keycode           physical_keycode    @ 	   key_label             unicode           echo          script            InputEventJoypadButton        resource_local_to_scene           resource_name             device     ����   button_index         pressure          pressed           script      #   rendering/renderer/rendering_method         gl_compatibility*   rendering/renderer/rendering_method.mobile         gl_compatibility        