precision highp float;
precision highp int;

// Attributes
attribute vec3 position;
attribute vec3 normal;
attribute vec2 uv;
attribute vec4 color;

attribute vec3 trail0;
attribute vec3 trail1;
attribute vec3 trail2;
attribute vec3 trail3;
attribute vec3 trail4;

#include<instancesDeclaration>

// Uniforms
uniform mat4 world;
uniform mat4 worldViewProjection;
uniform mat4 viewProjection;
uniform int trailStep;
uniform int trailLength;

// Varying
varying vec3 vNormal;
varying vec2 vUV;
varying vec4 vColor;

int getTrailId(float fraction) {
    int index = int(floor((fraction) * float(trailLength-1) + 0.2));
    return index;
}

vec3 getTrail(int index) {
    index += trailStep;
    if (index >= trailLength) {
        index -= trailLength;
    }
    switch(index) {
        case 0:
        return trail0;
        case 1:
        return trail1;
        case 2:
        return trail2;
        case 3:
        return trail3;
        case 4:
        return trail4;
    }
    return vec3(0,0,0);
}

vec3 getDirection(int id) {
    vec3 forward;
    vec3 backward;
    vec3 point = getTrail(id).xyz;

    bool hasForward = id > 0;
    bool hasBackward = id < trailLength-1;

    if (hasForward) {
        vec3 prev = getTrail(id-1).xyz;
        forward = prev - point;
    }
    if (hasBackward) {
        vec3 next = getTrail(id+1).xyz;
        backward = point - next;
    }

    if (hasForward && hasBackward) {
        return normalize(forward + backward);
    } else if (hasForward) {
        return normalize(forward);
    } else if (hasBackward) {
        return normalize(backward);
    }
    return vec3(0,0,0);
}

void main() {
    #include<instancesVertex>

    vNormal = normal;
    vUV = uv;
    vColor = color;//vec4(1,1,1,1);

    bool isTrail = color.r < 0.1;

    if (isTrail) {
        vec2 trailPos = vec2(color.b - 0.5, color.g);

        int id = getTrailId(trailPos.y);
        vec3 trail = getTrail(id);
        vec3 direction = getDirection(id);

        trail.x -= direction.z * -trailPos.x;
        trail.z += direction.x * -trailPos.x;

        vec4 pos = vec4(trail, 1.0);
        //pos.xyz += position;
        gl_Position = (viewProjection * world * pos);// + (viewProjection * finalWorld * vec4(position,1.0));
        //gl_Position = (viewProjection * finalWorld * vec4(position,1.0));
        //vColor.rgb = vec3(trailPos.y, 0,0);
    } else {
        // vertices which are normal and nothing to do with the trail
        vec4 pos = vec4(position, 1.0);
        gl_Position = viewProjection * finalWorld * pos;
    }
}

