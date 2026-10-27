#version 440

// crystallize.frag: crystal facet effect.
// Voronoi cells with thin-film iridescence, caustic highlights, and a
// shatter burst. Uniforms: u_time, u_confidence, u_progress, u_shatter,
// u_width, u_height, u_morphR/G/B.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4  qt_Matrix;
    float qt_Opacity;
    float u_time;
    float u_confidence;
    float u_progress;
    float u_shatter;
    float u_width;
    float u_height;
    float u_morphR;
    float u_morphG;
    float u_morphB;
} ubuf;

const float PI  = 3.14159265359;
const float TAU = 6.28318530718;

vec2 hash2(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
    return fract(sin(p) * 43758.5453);
}
float hash1(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
float hash1f(float n) { return fract(sin(n) * 43758.5453); }

float vnoise(vec2 p) {
    vec2 i = floor(p); vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash1(i), hash1(i + vec2(1,0)), u.x),
               mix(hash1(i + vec2(0,1)), hash1(i + vec2(1,1)), u.x), u.y);
}

float fbm2(vec2 p) {
    return vnoise(p) * 0.6 + vnoise(p * 2.1 + vec2(3.7, 1.9)) * 0.4;
}

float hexGrid(vec2 p, float scale) {
    p *= scale;
    p.x *= 1.1547;
    vec2 p1 = mod(p,                    vec2(2.0, 3.464)) - vec2(1.0, 1.732);
    vec2 p2 = mod(p - vec2(1.0, 1.732), vec2(2.0, 3.464)) - vec2(1.0, 1.732);
    vec2 ap1 = abs(p1); vec2 ap2 = abs(p2);
    float d1 = max(dot(ap1, normalize(vec2(1.0, 1.732))), ap1.x);
    float d2 = max(dot(ap2, normalize(vec2(1.0, 1.732))), ap2.x);
    return smoothstep(0.80, 0.97, min(d1, d2));
}

vec3 voronoiSDF(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);

    float F1 = 8.0, F2 = 8.0;
    vec2  cellId = vec2(0.0);

    for (int y = -2; y <= 2; y++) {
        for (int x = -2; x <= 2; x++) {
            vec2 neighbor = vec2(float(x), float(y));
            vec2 point    = hash2(i + neighbor);
            point = 0.5 + 0.5 * sin(ubuf.u_time * 0.25 + TAU * point);
            vec2  diff = neighbor + point - f;
            float dist = dot(diff, diff);
            if (dist < F1) { F2 = F1; F1 = dist; cellId = i + neighbor; }
            else if (dist < F2) { F2 = dist; }
        }
    }
    return vec3(sqrt(F1), cellId.x + cellId.y * 57.0, sqrt(F2) - sqrt(F1));
}

vec3 thinFilm(float thickness, float angle, float t) {
    float phaseR = thickness / 700.0 * 18.0 + angle * 2.1 + t * 0.4;
    float phaseG = thickness / 530.0 * 18.0 + angle * 2.5 + t * 0.5;
    float phaseB = thickness / 440.0 * 18.0 + angle * 3.0 + t * 0.6;
    return vec3(
        sin(phaseR) * 0.5 + 0.5,
        sin(phaseG) * 0.5 + 0.5,
        sin(phaseB) * 0.5 + 0.5
    );
}

float sdSegment(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}

void main() {
    vec2  uv  = qt_TexCoord0;
    float asp = ubuf.u_width / ubuf.u_height;
    vec2  uvA = vec2(uv.x * asp, uv.y);

    vec3  morphCol   = vec3(ubuf.u_morphR, ubuf.u_morphG, ubuf.u_morphB);
    vec3  ghostWhite = vec3(0.878, 0.969, 1.000);
    vec3  obsidian   = vec3(0.039, 0.039, 0.039);

    vec3  col   = vec3(0.0);
    float alpha = 0.0;

    float spreadMask = 1.0 - smoothstep(
        ubuf.u_progress - 0.20,
        ubuf.u_progress + 0.20,
        uv.x
    );
    float crystalStrength = spreadMask * ubuf.u_progress;

    if (crystalStrength > 0.005) {

        float cellScale = 2.8 + ubuf.u_confidence * 1.4;
        vec3  vor = voronoiSDF(uv * cellScale + ubuf.u_time * 0.04);
        float F1       = vor.x;
        float cellId   = vor.y;
        float boundary = vor.z;

        float hexEdge = hexGrid(uv, 3.2 + ubuf.u_confidence * 0.8);

        float facetThickness = 180.0 + hash1f(cellId) * 320.0
                             + vnoise(uv * 2.0 + ubuf.u_time * 0.03) * 80.0;
        float facetAngle = hash1f(cellId * 7.3) * TAU;
        vec3  filmColor  = thinFilm(facetThickness, facetAngle, ubuf.u_time);
        filmColor = mix(filmColor, morphCol, 0.45);

        float causticMask = exp(-F1 * F1 * 18.0);
        float causticNoise = vnoise(uv * 6.0 + ubuf.u_time * 0.08) * 0.5 + 0.5;
        float caustic = causticMask * causticNoise * ubuf.u_confidence * 0.6;

        float edgeSharp = exp(-boundary * boundary * 80.0);
        float edgeCombined = max(edgeSharp, hexEdge * 0.7);

        float edgeR = exp(-(boundary - 0.005) * (boundary - 0.005) * 80.0);
        float edgeG = exp(-(boundary)          * (boundary)          * 80.0);
        float edgeB = exp(-(boundary + 0.005) * (boundary + 0.005) * 80.0);
        vec3  chromaEdge = vec3(edgeR, edgeG, edgeB) * 0.5;

        vec3 interiorCol = mix(obsidian, morphCol * 0.5, ubuf.u_confidence * 0.4);
        interiorCol = mix(interiorCol, filmColor, F1 * 0.6 * ubuf.u_confidence);

        vec3 edgeCol = mix(morphCol, ghostWhite, edgeSharp * ubuf.u_confidence * 0.8);
        edgeCol += chromaEdge * 0.6;

        vec3 crystalCol = mix(interiorCol, edgeCol, edgeCombined);
        crystalCol += mix(morphCol, ghostWhite, 0.6) * caustic;
        crystalCol += morphCol * (1.0 - F1) * 0.15 * ubuf.u_confidence;

        float frostFront = ubuf.u_progress + 0.12;
        float frostDist  = abs(uv.x - frostFront);
        float frostNoise = fbm2(uv * 4.0 + ubuf.u_time * 0.15) * 0.5 + 0.5;
        float frost = exp(-frostDist * frostDist / 0.006)
                    * frostNoise * ubuf.u_progress * 0.5;
        crystalCol += morphCol * frost * 0.35;

        float crystalAlpha = (edgeCombined * 0.45
                            + caustic * 0.25
                            + frost * 0.20
                            + (1.0 - F1) * 0.08 * ubuf.u_confidence)
                           * crystalStrength;

        col   += crystalCol * crystalStrength;
        alpha += crystalAlpha;
    }

    if (ubuf.u_shatter > 0.005) {
        float s      = ubuf.u_shatter;
        vec2  center = vec2(0.5, 0.5);
        vec2  p      = uv - center;
        float dist   = length(p);
        float angle  = atan(p.y, p.x);

        vec2 warpQ = vec2(
            fbm2(p * 3.0 + vec2(ubuf.u_time * 0.2)),
            fbm2(p * 3.0 + vec2(1.7, 9.2) + ubuf.u_time * 0.15)
        );
        vec2 warpedP = p + warpQ * 0.08 * s;
        float warpedDist = length(warpedP);

        float waveR  = s * 0.52;
        float wave   = exp(-pow(warpedDist - waveR, 2.0) / 0.0025)
                     * s * (1.0 - s) * 2.5;
        vec3  waveCol = mix(morphCol, ghostWhite, s * 0.6);
        col   += waveCol * wave;
        alpha += wave * 0.7;

        for (int i = 0; i < 6; i++) {
            float shardAngle = float(i) * (PI / 3.0);
            shardAngle += hash1f(float(i) * 3.7) * 0.15 - 0.075;

            vec2 shardDir = vec2(cos(shardAngle), sin(shardAngle));

            float innerR = 0.02 + s * 0.04;
            float outerR = s * 0.65 + hash1f(float(i) * 5.1) * s * 0.15;
            vec2  shardA = shardDir * innerR;
            vec2  shardB = shardDir * outerR;

            float shardDist = sdSegment(p, shardA, shardB);

            float t_along = clamp(dot(p - shardA, shardDir) / max(outerR - innerR, 0.001), 0.0, 1.0);
            float shardWidth = mix(0.008, 0.002, t_along) * (1.0 - s * 0.5);

            float shardGlow = exp(-shardDist * shardDist / (shardWidth * shardWidth));
            shardGlow *= (1.0 - s) * (1.0 - t_along * 0.6);

            float shardFilmT = hash1f(float(i) * 11.3) * 0.5 + s * 0.3;
            vec3  shardCol   = mix(morphCol, ghostWhite, shardFilmT);
            shardCol.r += t_along * 0.15;
            shardCol.b -= t_along * 0.10;

            col   += shardCol * shardGlow * 1.8;
            alpha += shardGlow * 0.8;
        }

        float ring2 = exp(-pow(dist - s * 0.22, 2.0) / 0.0008)
                    * s * (1.0 - s) * 1.2;
        col   += morphCol * ring2;
        alpha += ring2 * 0.4;

        float voidExpand = smoothstep(0.0, 0.7, s);
        float voidFill   = smoothstep(waveR * 0.6, waveR * 0.1, dist) * voidExpand;
        col   = mix(col, vec3(0.0), voidFill * 0.85);
        alpha = mix(alpha, 0.0, voidFill * 0.8);
    }

    fragColor = vec4(col * alpha, alpha * ubuf.qt_Opacity);
}
