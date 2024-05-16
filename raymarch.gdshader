shader_type canvas_item;
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
