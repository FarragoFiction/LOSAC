#ifdef GL_ES
precision highp float;
#endif

// Samplers
varying vec2 vUV;
uniform sampler2D textureSampler;
uniform sampler2D depthSampler;

// Parameters
uniform vec2 screenSize;
uniform mat4 invProjView;
uniform float nearZ;
uniform float farZ;

struct DepthInfo {
    float depth;
    float left;
    float right;
    float top;
    float bottom;
    vec2 dir;
    float mag;
};

vec2 offsetSample(vec2 direction) {
    if (abs(direction.x) > abs(direction.y)) {
        return vec2(sign(direction.x), 0.0) / screenSize;
    }

    return vec2(0.0, sign(direction.y)) / screenSize;
}

float colourDifference(vec4 c1, vec4 c2) {
    float dr = abs(c1.r - c2.r);
    float dg = abs(c1.g - c2.g);
    float db = abs(c1.b - c2.b);

    float l1 = 0.299 * c1.r + 0.587 * c1.g + 0.114 * c1.b;
    float l2 = 0.299 * c2.r + 0.587 * c2.g + 0.114 * c2.b;

    float dl = l1-l2;

    return dl * 0.65 + (0.299 * dr + 0.587 * dg + 0.114 * db) * 0.35;
}

vec2 colourVariance(vec2 coord, vec3 dim) {
    vec4 middle = texture2D(textureSampler, coord);
    vec2 total = vec2(0.0);

    total += colourDifference(middle, texture2D(textureSampler, coord - dim.zy)) * vec2( 0.0, -1.0);
    total += colourDifference(middle, texture2D(textureSampler, coord - dim.xz)) * vec2(-1.0,  0.0);
    total += colourDifference(middle, texture2D(textureSampler, coord + dim.xz)) * vec2( 1.0,  0.0);
    total += colourDifference(middle, texture2D(textureSampler, coord + dim.zy)) * vec2( 0.0,  1.0);

    return total * 0.25;
}

vec3 applyTransform(vec3 v, mat4 m) {

    float rx = v.x * m[0][0] + v.y * m[1][0] + v.z * m[2][0] + m[3][0];
    float ry = v.x * m[0][1] + v.y * m[1][1] + v.z * m[2][1] + m[3][1];
    float rz = v.x * m[0][2] + v.y * m[1][2] + v.z * m[2][2] + m[3][2];
    float rw = 1.0 / (v.x * m[0][3] + v.y * m[1][3] + v.z * m[2][3] + m[3][3]);

    vec3 coord = vec3(rx * rw, ry * rw, rz * rw);
    return coord;
}

vec3 worldPosCalc(float depth, vec2 uv) {
    float z = 2.0 * depth - 1.0;
    vec3 screenSource = vec3(uv * 2.0 - 1.0, z);
    vec3 coord = applyTransform(screenSource, invProjView);

    float val = screenSource.x * invProjView[0][3] + screenSource.y * invProjView[1][3] + screenSource.z * invProjView[2][3] + invProjView[3][3];
    return coord;
}

vec3 worldPos(float depth, vec2 uv) {
    return mix(worldPosCalc(0.0, uv), worldPosCalc(1.0, uv), depth);
}

float dSmooth(float min, float max, float val) {
    float v1 = 1.0 - clamp(0.0,1.0,val);
    float v2 = 1.0 - (v1 * v1);
    return mix(min, max, v2);
}

vec3 depthMix(float depth) {
    float t1 = 0.02;
    float t2 = 0.125;

    float red = dSmooth(1.0, 0.0, depth / t1);
    float blue = dSmooth(0.0, 1.0, (depth-t1) / (t2-t1));

    return vec3(red, 1.0-(red+blue), blue);
}

float SimplexPerlin3D( vec3 P )
{
    //  https://github.com/BrianSharpe/Wombat/blob/master/SimplexPerlin3D.glsl

    //  simplex math constants
    const float SKEWFACTOR = 1.0/3.0;
    const float UNSKEWFACTOR = 1.0/6.0;
    const float SIMPLEX_CORNER_POS = 0.5;
    const float SIMPLEX_TETRAHADRON_HEIGHT = 0.70710678118654752440084436210485;    // sqrt( 0.5 )

    //  establish our grid cell.
    P *= SIMPLEX_TETRAHADRON_HEIGHT;    // scale space so we can have an approx feature size of 1.0
    vec3 Pi = floor( P + dot( P, vec3( SKEWFACTOR) ) );

    //  Find the vectors to the corners of our simplex tetrahedron
    vec3 x0 = P - Pi + dot(Pi, vec3( UNSKEWFACTOR ) );
    vec3 g = step(x0.yzx, x0.xyz);
    vec3 l = 1.0 - g;
    vec3 Pi_1 = min( g.xyz, l.zxy );
    vec3 Pi_2 = max( g.xyz, l.zxy );
    vec3 x1 = x0 - Pi_1 + UNSKEWFACTOR;
    vec3 x2 = x0 - Pi_2 + SKEWFACTOR;
    vec3 x3 = x0 - SIMPLEX_CORNER_POS;

    //  pack them into a parallel-friendly arrangement
    vec4 v1234_x = vec4( x0.x, x1.x, x2.x, x3.x );
    vec4 v1234_y = vec4( x0.y, x1.y, x2.y, x3.y );
    vec4 v1234_z = vec4( x0.z, x1.z, x2.z, x3.z );

    // clamp the domain of our grid cell
    Pi.xyz = Pi.xyz - floor(Pi.xyz * ( 1.0 / 69.0 )) * 69.0;
    vec3 Pi_inc1 = step( Pi, vec3( 69.0 - 1.5 ) ) * ( Pi + 1.0 );

    //	generate the random vectors
    vec4 Pt = vec4( Pi.xy, Pi_inc1.xy ) + vec2( 50.0, 161.0 ).xyxy;
    Pt *= Pt;
    vec4 V1xy_V2xy = mix( Pt.xyxy, Pt.zwzw, vec4( Pi_1.xy, Pi_2.xy ) );
    Pt = vec4( Pt.x, V1xy_V2xy.xz, Pt.z ) * vec4( Pt.y, V1xy_V2xy.yw, Pt.w );
    const vec3 SOMELARGEFLOATS = vec3( 635.298681, 682.357502, 668.926525 );
    const vec3 ZINC = vec3( 48.500388, 65.294118, 63.934599 );
    vec3 lowz_mods = vec3( 1.0 / ( SOMELARGEFLOATS.xyz + Pi.zzz * ZINC.xyz ) );
    vec3 highz_mods = vec3( 1.0 / ( SOMELARGEFLOATS.xyz + Pi_inc1.zzz * ZINC.xyz ) );
    Pi_1 = ( Pi_1.z < 0.5 ) ? lowz_mods : highz_mods;
    Pi_2 = ( Pi_2.z < 0.5 ) ? lowz_mods : highz_mods;
    vec4 hash_0 = fract( Pt * vec4( lowz_mods.x, Pi_1.x, Pi_2.x, highz_mods.x ) ) - 0.49999;
    vec4 hash_1 = fract( Pt * vec4( lowz_mods.y, Pi_1.y, Pi_2.y, highz_mods.y ) ) - 0.49999;
    vec4 hash_2 = fract( Pt * vec4( lowz_mods.z, Pi_1.z, Pi_2.z, highz_mods.z ) ) - 0.49999;

    //	evaluate gradients
    vec4 grad_results = inversesqrt( hash_0 * hash_0 + hash_1 * hash_1 + hash_2 * hash_2 ) * ( hash_0 * v1234_x + hash_1 * v1234_y + hash_2 * v1234_z );

    //	Normalization factor to scale the final result to a strict 1.0->-1.0 range
    //	http://briansharpe.wordpress.com/2012/01/13/simplex-noise/#comment-36
    const float FINAL_NORMALIZATION = 37.837227241611314102871574478976;

    //  evaulate the kernel weights ( use (0.5-x*x)^3 instead of (0.6-x*x)^4 to fix discontinuities )
    vec4 kernel_weights = v1234_x * v1234_x + v1234_y * v1234_y + v1234_z * v1234_z;
    kernel_weights = max(0.5 - kernel_weights, 0.0);
    kernel_weights = kernel_weights*kernel_weights*kernel_weights;

    //	sum with the kernel and return
    return dot( kernel_weights, grad_results ) * FINAL_NORMALIZATION;
}

float worldNoise(float depth, vec2 uv) {
    float scale = 4.0;
    vec3 mixval = depthMix(depth);

    vec3 world = worldPos(depth, uv);

    float val = mixval.r * SimplexPerlin3D(world * scale)
        + mixval.g * SimplexPerlin3D(world * 0.6 * scale)
        + mixval.b * SimplexPerlin3D(world * 0.1 * scale) * 1.5;

    return val;
}

DepthInfo depthVariance(vec2 coord, vec3 dim) {
    float middle = texture2D(depthSampler, coord).r;
    vec2 dir = vec2(0.0);
    float mag = 0.0;

    float d;

    float top = texture2D(depthSampler, coord - dim.zy).r;
    d = middle - top;
    dir += clamp(d, 0.0,1.0) * vec2( 0.0, -1.0);
    mag += d;

    float left = texture2D(depthSampler, coord - dim.xz).r;
    d = middle - left;
    dir += clamp(d, 0.0,1.0) * vec2(-1.0,  0.0);
    mag += d;

    float right = texture2D(depthSampler, coord + dim.xz).r;
    d = middle - right;
    dir += clamp(d, 0.0,1.0) * vec2( 1.0,  0.0);
    mag += d;

    float bottom = texture2D(depthSampler, coord + dim.zy).r;
    d = middle - bottom;
    dir += clamp(d, 0.0,1.0) * vec2( 0.0,  1.0);
    mag += d;

    return DepthInfo(middle, left, right, top, bottom, dir * 0.25, mag * 0.25);
}

void main(void)
{
    vec3 dim = vec3(vec2(1.0) / screenSize, 0.0);
    gl_FragColor = texture2D(textureSampler, vUV);

    DepthInfo depth = depthVariance(vUV, dim);
    vec2 depthDiff = depth.dir;
    vec2 colourDiff = colourVariance(vUV, dim);

    float depthMag = length(depthDiff);
    float colourMag = length(colourDiff);

    float depthThreshold = 0.0005;
    float colourDepthThreshold = -0.0005;
    float colourThreshold = 0.02;

    bool isOuterEdge = depthMag > depthThreshold;
    bool isInnerEdge = depth.mag > colourDepthThreshold && colourMag > colourThreshold;

    if ( isOuterEdge || isInnerEdge ) {
        float noise;
        vec2 samplePos = vUV;

        if (!isOuterEdge) {
            // we're on an interior edge, sample directly
            noise = worldNoise(depth.depth, vUV);
            samplePos += offsetSample(colourDiff * noise);
        } else {
            // we're on an exterior edge, sample offset instead
            vec2 o = offsetSample(depth.dir);
            float d = texture2D(depthSampler, vUV + o).r;
            noise = worldNoise(d, vUV + o);
            samplePos += o;
        }

        if (noise > 0.0) {
            gl_FragColor = texture2D(textureSampler, samplePos);
        }
    }

    gl_FragColor = vec4(depth.depth,depth.depth,depth.depth,1.0);
}