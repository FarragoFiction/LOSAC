precision highp float;

// Attributes
attribute vec3 position;
attribute vec3 normal;
attribute vec2 uv;

// Uniforms
uniform mat4 worldViewProjection;

// Varying
varying vec4 vPosition;
varying vec3 vNormal;
varying vec2 vUV;

void main() {
    vec4 p = vec4( position, 1. );

    vPosition = p;
    vNormal = normal;
    vUV = uv;

    gl_Position = worldViewProjection * p;
}