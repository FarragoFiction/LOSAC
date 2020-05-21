// Set the precision for data types used in this shader
precision highp float;
precision highp int;

// Default THREE.js uniforms available to both fragment and vertex shader
uniform mat4 modelMatrix;
uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform mat4 viewMatrix;
uniform mat3 normalMatrix;

// Default uniforms provided by ShaderFrog.
uniform vec3 cameraPosition;
uniform float time;

// A uniform unique to this shader. You can modify it to the using the form
// below the shader preview. Any uniform you add is automatically given a form
uniform vec3 color;
uniform vec3 lightPosition;

// Example varyings passed from the vertex shader
varying vec3 vPosition;
varying vec3 vNormal;
varying vec2 vUv;
varying vec2 vUv2;

//---------------------------------------------------------

struct Ray
{
    vec3 o;		// origin
    vec3 d;		// direction
};

struct Hit
{
    float t;	// solution to p=o+t*d
    vec3 n;		// normal
};
const Hit noHit = Hit(1e10, vec3(0.));

struct Cone
{
	float cosa;	// half cone angle
    float h;	// height
    vec3 c;		// tip position
    vec3 v;		// axis
};

//---------------------------------------------------------

Hit intersectCone(Cone s, Ray r)
{
    vec3 co = r.o - s.c;

    float a = dot(r.d,s.v)*dot(r.d,s.v) - s.cosa*s.cosa;
    float b = 2. * (dot(r.d,s.v)*dot(co,s.v) - dot(r.d,co)*s.cosa*s.cosa);
    float c = dot(co,s.v)*dot(co,s.v) - dot(co,co)*s.cosa*s.cosa;

    float det = b*b - 4.*a*c;
    if (det < 0.) return noHit;

    det = sqrt(det);
    float t1 = (-b - det) / (2. * a);
    float t2 = (-b + det) / (2. * a);

    // This is a bit messy; there ought to be a more elegant solution.
    float t = t1;
    if (t < 0. || t2 > 0. && t2 < t) t = t2;
    if (t < 0.) return noHit;

    vec3 cp = r.o + t*r.d - s.c;
    float h = dot(cp, s.v);
    if (h < 0. || h > s.h) return noHit;

    vec3 n = normalize(cp * dot(s.v, cp) / dot(cp, cp) - s.v);

    return Hit(t, n);
}

//---------------------------------------------------------

float calcWobble(vec2 uv, float scale) {
    float rad = length(uv);
    vec2 wobble = sin(fract((uv * scale) + (time * vec2(0.35,0.5))) * 3.14192 * 2.0);
    return clamp(wobble.x * wobble.y * 0.05 + rad, 0.0,1.0);
}

float circles(vec2 uv) {
    return fract(length(uv)*10.0);
}

float tunnel(vec2 uv) {
    float angle = 0.0 ;
    float radius = length(uv) ;
    if (uv.x != 0.0 && uv.y != 0.0){
        angle = degrees(atan(uv.y,uv.x)) ;
    }
    
    float wobble = calcWobble(uv, 3.0);
    float wobbleRadius = radius + wobble * 0.35 * clamp(1.25 - radius, 0.0, 1.0);
    
    float amod = mod(angle+60.0*time-720.0*log(wobbleRadius), 120.0) ;
    if (amod<60.0){
        return 0.0;
    } else{
        return clamp(1.35 * (radius - 0.15), 0.0,1.0);         
    }
}

//---------------------------------------------------------

const vec4 redDark = vec4(0.6,0.0,0.0,1.0);
const vec4 redMid = vec4(0.8,0.0,0.0,1.0);
const vec4 redLight = vec4(1.0,0.0,0.0,1.0);

void main() {

    // Calculate the real position of this pixel in 3d space, taking into account
    // the rotation and scale of the model. It's a useful formula for some effects.
    // This could also be done in the vertex shader
    vec3 worldPosition = ( modelMatrix * vec4( vPosition, 1.0 )).xyz;

    /*// Calculate the normal including the model rotation and scale
    vec3 worldNormal = normalize( vec3( modelMatrix * vec4( vNormal, 0.0 ) ) );

    vec3 lightVector = normalize( lightPosition - worldPosition );

    // An example simple lighting effect, taking the dot product of the normal
    // (which way this pixel is pointing) and a user generated light position
    float brightness = dot( worldNormal, lightVector );

    // Fragment shaders set the gl_FragColor, which is a vector4 of
    // ( red, green, blue, alpha ).
    gl_FragColor = vec4( color * brightness, 1.0 );*/
    
    
    float rad = clamp(1.0 - length(vUv * 2.0 - 1.0), 0.0,1.0);
    
    vec2 wobble = sin(fract((vUv * 5.0) + (time * vec2(0.35,0.5))) * 3.14192 * 2.0);
    float wobbleOffset = clamp(wobble.x * wobble.y * 0.05 + rad, 0.0,1.0);
    //float wobbleOffset = calcWobble(vUv * 2.0 - 1.0);
    
    if (wobbleOffset < 0.05) {
        // exterior
        discard;
    } else if (wobbleOffset < 0.1) {
        // border
        gl_FragColor = redLight;
    } else {
        // interior
        
        vec3 raydir = normalize(worldPosition - cameraPosition);
        
        float facing = dot(vNormal, raydir);
        
        if (facing > 0.0) {
            // portal rear
            gl_FragColor = redDark;
        } else {
            // portal front
            
            Cone cone = Cone(0.965, 4.5, vec3(0.0,0.0,-4.0), vec3(0.0,0.0,1.0));
            vec2 coord = vec2(vUv*2.0 - 1.0);
            vec3 rayStart = vec3(coord, 0.0);
            Ray ray = Ray(rayStart, raydir);
            
            Hit hit = intersectCone(cone, ray);
            if (hit.t >= 1e10) {
                discard;
            }
            vec2 o = (raydir * hit.t).xy* 0.5;
            vec2 oCoord = (vUv + o)*2.0 - 1.0;

            float c = tunnel(oCoord);
            vec4 col = mix(redDark, redMid, c);//vec4(c,c,c,1.0);
            //vec4 col = vec4(o*0.5 + 0.5, 0.5, 1.0);
            
            gl_FragColor = col;
        }
    }
}