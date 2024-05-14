shader_type canvas_item;
render_mode unshaded;

uniform vec3 light01 = vec3(-2.0f, 3.0f, -3.0f);

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
    //vec4 plane = {0.0, 1.0, -1.0,-1.0};
    //float plane_4 = getSignedDistanceFromPlane(p, plane);
    vec4 plane2 = vec4(0.1*sin(TIME/5.0), 1.0, -1.0,-1.0);
    float plane_5 = sdfPlane(p, plane2);
    //vec3 gyroid = vec3(-1.0f, -0.5f, 0.0f);
    //float gyroid_6 = sdfGyroid(p, 15.0f);
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
    float finalDistance = max(sphere_1,sphere_2);
	finalDistance = min(opSmoothUnion(plane_5,sphere_3, 0.3), finalDistance);
    //finalDistance = min(sphere_3,finalDistance); //fmin(fmax(gyroid_6,plane_5),finalDistance);
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


vec3 checkLightVisibility(vec3 hitPosition, vec3 lightPosition) {
	const float MINIMUM_HIT_DISTANCE = 0.001f;
	const float MAXIMUM_TRACE_DISTANCE = 1000.0f;
    float stepSize = 0.1;
    int numberOfSteps = 64;
    // Calculate the ray direction from the hit position to the light
    vec3 rayDirection = normalize(lightPosition - hitPosition);

    // Set the initial ray origin to a small offset from the hit position
    // This avoids self-intersection with the hit geometry
    const float epsilon = 1.1f;
    vec3 rayOrigin = hitPosition + rayDirection * epsilon;

    // Ray march towards the light source
    for (int i = 0; i < numberOfSteps; ++i) {
        vec3 currentPosition = rayOrigin + (float(i) * stepSize) * rayDirection;

        // Check if the current position is beyond the light source
        if (length(currentPosition - lightPosition) < epsilon) {
            // The light source is visible
            vec3 normal = calculateNormal(currentPosition);
            vec3 directionToLight = normalize(lightPosition - currentPosition);
            float diffuseIntensity = max(0.0, dot(normal, directionToLight));
            return vec3(diffuseIntensity,diffuseIntensity,diffuseIntensity);
        }

        // Check if the current position intersects with any geometry
        float distanceToClosest = mapTheWorld(currentPosition);

        // If the intersection is very close, we've hit something before reaching the light
        if (distanceToClosest < MINIMUM_HIT_DISTANCE) {
            return vec3(0.0f,0.0f,0.0f);;
        }
    }

    // If we've reached this point, the light source is visible
    vec3 normal = calculateNormal(hitPosition);
    vec3 directionToLight = normalize(lightPosition - hitPosition);
    float diffuseIntensity = max(0.0, dot(normal, directionToLight));
    vec3 c = vec3(diffuseIntensity,diffuseIntensity,diffuseIntensity);
    return c;
}

vec3 rayMarch(vec3 rayOrigin, vec3 rayDirection) {
	vec3 bg = vec3(0.1,0.1,0.2);
    int numberOfSteps = 100;
	const float THICKNESS = 0.001;
	float progress = 0.0;
	
    vec3 currentPosition = rayOrigin;
	for (int i = 0; i < numberOfSteps; ++i) {
		currentPosition = rayOrigin + progress*rayDirection;
		vec3 spherePosition = vec3(0.0,0.0,0.0);
		float distanceToClosest = mapTheWorld(currentPosition);
		if (distanceToClosest < THICKNESS) {
			vec3 normal = calculateNormal(currentPosition);
			vec3 directionToLight = normalize(currentPosition - light01);
            vec3 c = checkLightVisibility(currentPosition, light01);
            c *= normal;
			return c;
		}
		progress = progress + distanceToClosest;
	}
	return bg;
}

void fragment() {
    // Initial renderer color
    vec3 cameraPosition = vec3(0.0f,0.0f,-5.0f);
	float aspectRatio = SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y;
	vec2 uv = (UV-0.5)*2.0;
	uv.y *= -1.0;
	uv.x = uv.x/aspectRatio;
    vec3 rayDirection = vec3(uv,1.0f);
	/*
	vec3 offsetX = vec3(SCREEN_PIXEL_SIZE.x/2.0, 0.0, 0.0);
	vec3 offsetY = vec3(0.0, SCREEN_PIXEL_SIZE.y/2.0, 0.0);

    vec3 c1 = rayMarch(cameraPosition+offsetX+offsetY, rayDirection);
    vec3 c2 = rayMarch(cameraPosition-offsetX+offsetY, rayDirection);
    vec3 c3 = rayMarch(cameraPosition+offsetX-offsetY, rayDirection);
    vec3 c4 = rayMarch(cameraPosition-offsetX-offsetY, rayDirection);
    vec3 c = (c1+c2+c3+c4)/4.0;
	*/
    vec3 c = rayMarch(cameraPosition, rayDirection);
	
	// Called for every pixel the material is visible on.
	COLOR = vec4(c, 1.0);
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
