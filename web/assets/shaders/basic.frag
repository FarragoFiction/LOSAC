precision highp float;
precision highp int;

varying vec4 vPosition;
varying vec3 vNormal;
varying vec2 vUV;
varying vec4 vColor;

void main() {
    gl_FragColor = vColor;
}