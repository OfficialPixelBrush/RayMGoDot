shader_type canvas_item;
render_mode unshaded;

uniform vec3 light01 = vec3(2.29, 4.35, -4.275);
uniform vec3 cameraPosition = vec3(0.0f,0.0f,-5.0f);
uniform vec2 cameraOffset = vec2(0.0f,0.0f);
uniform float fieldOfView = 0.0f;
uniform vec4 plane2 = vec4(0.0, 1.0, -1.0,-1.0);
uniform float bgGradient = 1.0f;
uniform vec3 bg1 = vec3(0.1,0.1,0.2);
uniform vec3 bg2 = vec3(0.455,0.52,0.835);

void vertex() {
	// Called for every vertex the material is visible on.
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

/* Compute distance to a gyroid */
float sdfGyroid(vec3 p, float k) {
    p = p * k + TIME;
    return sin(p.x) * cos(p.y) + sin(p.y) * cos(p.z) + sin(p.z) * cos(p.x);
}

// From https://www.shadertoy.com/view/4sXXRN
float dot2( in vec3 v ) { return dot(v,v); }
float udTriangle( vec3 p, vec3 a, vec3 b, vec3 c )
{
  vec3 ba = b - a; vec3 pa = p - a;
  vec3 cb = c - b; vec3 pb = p - b;
  vec3 ac = a - c; vec3 pc = p - c;
  vec3 nor = cross( ba, ac );

  return sqrt(
    (sign(dot(cross(ba,nor),pa)) +
     sign(dot(cross(cb,nor),pb)) +
     sign(dot(cross(ac,nor),pc))<2.0)
     ?
     min( min(
     dot2(ba*clamp(dot(ba,pa)/dot2(ba),0.0,1.0)-pa),
     dot2(cb*clamp(dot(cb,pb)/dot2(cb),0.0,1.0)-pb) ),
     dot2(ac*clamp(dot(ac,pc)/dot2(ac),0.0,1.0)-pc) )
     :
     dot(nor,pa)*dot(nor,pa)/dot2(nor) );
}

float opUnion( float d1, float d2 ) {  return min(d1,d2); }

float opSubtraction( float d1, float d2 ) { return max(d1,-d2); }

float opIntersection( float d1, float d2 ) { return max(d1,d2); }

float opSmoothUnion( float d1, float d2, float k ) 
{
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h);
}

float mapTheWorld(vec3 p)
{
    float value = sin(TIME/5.0f);
    float value2 = cos(TIME/5.0f)/20.0;
    float value3 = sin(TIME/2.0f);
    float value4 = cos(TIME/2.0f);
    vec3 circle = vec3(0.0f+value,0.0f+value3,-1.9f+value2 );
    float sphere_1 = sdfSphere(p, circle, 1.0);
    vec3 circle2 = vec3(0.5f, 0.5f, -1.9f);
    float sphere_2 = sdfSphere(p, circle2, 1.0);
    vec3 circle3 = vec3(-2.5f, -0.5f+value4, -1.0f);
    float sphere_3 = sdfSphere(p, circle3, 1.5);
    vec3 triP1 = vec3(0.0, 2.0, -1.0);
    vec3 triP2 = vec3(0.0, 0.0, -1.0);
    vec3 triP3 = vec3(2.0, 1.0, -2.0);
    float tri_4 = udTriangle(p, triP1, triP2, triP3);
    float plane_5 = sdfPlane(p, plane2);
    vec3 gyroid = vec3(-1.0f, -0.5f, 0.0f);
    float gyroid_6 = sdfGyroid(p, 15.0f);
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
	finalDistance = min(opSmoothUnion(plane_5,sphere_3,0.3), finalDistance);
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

vec3 getSkybox(vec3 rayDirection) {
	return lerp(bg1,bg2,rayDirection.y*bgGradient);
}

vec3 rayMarch(vec3 rayOrigin, vec3 rayDirection) {
	int numberOfSteps = 80;
	float minDistance = 0.001;
	float maxDistance = 100.0;
	float progress = 0.0;
	vec3 color = vec3(1.0);
	
	for (int i = 0; i < numberOfSteps; ++i) {
		vec3 currentPosition = rayOrigin + rayDirection * progress;
		float distanceToClosest = mapTheWorld(currentPosition);
		progress += distanceToClosest;
		color = vec3(float(i))/float(numberOfSteps);
		if (distanceToClosest < minDistance) { break; }
		if (progress > maxDistance) { break; }
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
	vec3 offsetX = vec3(SCREEN_PIXEL_SIZE.x*1.5, 0.0, 0.0);
	vec3 offsetY = vec3(0.0, SCREEN_PIXEL_SIZE.y*1.5, 0.0);

    vec3 c1 = rayMarch(cameraPosition+offsetX+offsetY, rayDirection);
    vec3 c2 = rayMarch(cameraPosition-offsetX+offsetY, rayDirection);
    vec3 c3 = rayMarch(cameraPosition+offsetX-offsetY, rayDirection);
    vec3 c4 = rayMarch(cameraPosition-offsetX-offsetY, rayDirection);
    vec3 c = (c1+c2+c3+c4)/4.0;
	
    //vec3 c = rayMarch(cameraPosition, rayDirection);
	
	// Called for every pixel the material is visible on.
	COLOR = vec4(c, 1.0);
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
