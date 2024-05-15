shader_type canvas_item;
render_mode unshaded;

uniform int antiAliasingLevel = 0;
uniform vec3 cameraPosition = vec3(0.0f,1.0f,-5.0f);
uniform vec3 cameraRotationAxis = vec3(0.0f,1.0f,0.0f);
uniform float cameraAngle = 0.0;
uniform vec2 cameraOffset = vec2(0.0f,0.0f);
uniform float fieldOfView = 0.0f;
uniform vec4 plane2 = vec4(0.0, 1.0, 0.0,0.5);
uniform float bgGradient = 4.93;
uniform vec3 bg1 = vec3(0.275,0.145,0.415);
uniform vec3 bg2 = vec3(0.98,0.405,0.44);
uniform vec3 skyboxAxis = vec3(0.4,0.2,0.1);
uniform float skyboxAngle = 0.5;
uniform vec3 voidColor = vec3(0.59,0.505,0.77);

void vertex() {
	// Called for every vertex the material is visible on.
}

vec3 rot3D(vec3 p, vec3 axis, float angle) {
	axis = normalize(axis);
	return mix(dot(axis,p) * axis, p, cos(angle)) + cross(axis,p) * sin(angle);
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

float sdBox( vec3 p, vec3 b, vec3 t, vec3 rotationAxis, float angle) {
	p -= t;
	p = rot3D(p,rotationAxis,angle);
	vec3 q = abs(p) - b;
	return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
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
    float plane_5 = sdfWavePlane(p, plane2, 1.0, 0.5*sin(TIME), vec2(1.0,1.0));
    float plane_6 = sdfWavePlane(p, plane2, 1.211, 0.25*cos(TIME), vec2(1.0,1.0));
    float gyroid_6 = sdfGyroid(p, 4.0f);
	vec3 boxSize = vec3(4.0,1.0,2.0);
	vec3 boxPos = vec3(-10.0,3.0,5);
	float box_7 = sdBox(p, boxSize, boxPos, vec3(0.0,1.0,0.0), TIME/3.0);
    /*
    vec3 box = { 1.0, 1.0, 1.0};
    vec3 box2 = { 0.0, 0.0, 0.0};
    vec3 boxSize = { 0.5, 0.5, 0.5};
    float box_7 = getSignedDistanceFromCube(box, box2, boxSize);
    */
    
    // Later we might have sphere_1, sphere_2, cube_3, etc...
    // fmax for itersection
    // fmin for both
    // fmax for itersection
    // fmin for both
    float finalDistance = opIntersection(sphere_1,sphere_2);
	finalDistance = min(opSmoothSubtraction(sphere_3,opSmoothIntersection(plane_6,plane_5, 0.1),0.1), finalDistance);
	finalDistance = min(box_7, finalDistance);
	//finalDistance = min(pryamid_8, finalDistance);
	//finalDistance = opSmoothUnion(tri_4, finalDistance,1.0);
    //finalDistance = max(gyroid_6,finalDistance); //fmin(fmax(gyroid_6,plane_5),finalDistance);
    //finalDistance = fmin(box_7,finalDistance);
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
		color += empty * getSkybox(rayDirection);
		if (distanceToClosest < minDistance) {
			//vec3 normal = calculateNormal(currentPosition);
			//color *= normal;
			//return getSkybox(rayDirection*normal);
			break;
		}
		if (progress > maxDistance) {
			return getSkybox(rayDirection);
		}
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
	rayDirection = rot3D(rayDirection, cameraRotationAxis, cameraAngle);
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
