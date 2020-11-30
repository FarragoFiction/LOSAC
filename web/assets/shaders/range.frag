precision highp float;
precision highp int;

varying vec4 vPosition;
varying vec3 vNormal;
varying vec2 vUV;
varying vec4 vColor;
varying float vDepthMetric;

uniform sampler2D depth;
uniform vec4 colour;

void main() {
    const float threshold = 0.01;

    vec2 screenCoords = gl_FragCoord.xy / vec2(textureSize(depth,0));

    float depthVal = texture2D(depth, screenCoords).r;
    float depthDiff = abs(depthVal - vDepthMetric);

    if (depthDiff > threshold) { discard; }

    float fraction = 1.0 - (depthDiff / threshold);

    gl_FragColor = vec4(colour.rgb, fraction * fraction * colour.a);
}