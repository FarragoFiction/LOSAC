precision highp float;
precision highp int;

varying vec4 vPosition;
varying vec3 vNormal;
varying vec2 vUV;
varying vec4 vColor;

uniform sampler2D depth;

void main() {
    float depthVal = texture2D(depth, gl_FragCoord.xy).a;
    gl_FragColor = vec4(depthVal,depthVal,depthVal,1.0);
    //gl_FragColor = vColor;

    gl_FragColor = texture2D(depth, vUV);
}