precision highp float;
precision highp int;

// Attributes
attribute vec3 position;
attribute vec3 normal;
attribute vec2 uv;
attribute vec4 color;
#include<instancesDeclaration>

// Uniforms
uniform mat4 worldViewProjection;
uniform mat4 viewProjection;
uniform vec2 depthValues;

// Varying
varying vec3 vNormal;
varying vec2 vUV;
varying vec4 vColor;
varying float vDepthMetric;

void main() {
    #include<instancesVertex>
    vec4 p = vec4( position, 1. );

    vNormal = normal;
    vUV = uv;
    vColor = color;

    gl_Position = viewProjection * finalWorld * p;

    vDepthMetric = ((gl_Position.z + depthValues.x) / (depthValues.y));
}