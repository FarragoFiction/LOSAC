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
uniform float tickFraction;
uniform vec3 cameraPos;

// Varying
varying vec3 vNormal;
varying vec2 vUV;
varying vec4 vColor;

int getTrailId(float fraction) {
    int index = int(floor((fraction) * float(trailLength-1) + 0.2));
    return index;
}

vec3 getTrailBase(int index) {
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

vec3 getTrail(int index) {
    if (index == 0) {
        return (mat4(world0, world1, world2, world3) * vec4(0.0,0.0,0.0, 1.0)).xyz;
    }
    vec3 trail = getTrailBase(index);
    vec3 next = getTrailBase(index-1);
    return mix(trail, next, vec3(tickFraction));
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
        vec2 trailData = vec2(color.b - 0.5, color.g);

        int id = getTrailId(trailData.y);
        vec3 trailPos = getTrail(id);
        vec3 direction = getDirection(id);

        vec3 cameraDir = cameraPos - trailPos;

        vec3 offset = normalize(cross(direction, cameraDir));

        //trailPos.x -= direction.z * -trailData.x;
        //trailPos.z += direction.x * -trailData.x;

        trailPos += offset * -trailData.x;

        vec4 pos = vec4(trailPos, 1.0);
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

