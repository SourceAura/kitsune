#version 440
// pulse.frag — energy in the glass
// Filament veins sleep in the blurred ground. A surge sends a front of
// light across them; now and then the whole field crackles. Sporadic by
// design — the QML envelope decides when; the shader only draws.
//
// Uniforms:
//   u_time     — continuous seconds
//   u_surge    — 0–1, surge envelope
//   u_front    — surge front position in uv.x (travels -0.35 to 1.35)
//   u_crackle  — 0–1, crackle flare envelope
//   u_calm     — baseline filament strength (a whisper)

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float u_time;
    float u_surge;
    float u_front;
    float u_crackle;
    float u_calm;
};

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 4; i++) { v += a * noise(p); p *= 2.03; a *= 0.55; }
    return v;
}

void main() {
    vec2 uv = qt_TexCoord0;
    float drift = u_time * 0.014;
    float f = fbm(uv * vec2(9.0, 5.0) + vec2(drift, drift * 0.6));
    float vein = pow(clamp(1.0 - abs(2.0 * f - 1.0), 0.0, 1.0), 14.0);
    vec3 ecol = mix(vec3(0.55, 0.38, 1.0), vec3(0.25, 0.9, 1.0), fbm(uv * 3.0 + 7.0));
    float front = exp(-pow((uv.x - u_front) * 4.4, 2.0));
    float inten = u_calm + u_surge * front * 0.30 + u_crackle * 0.50;
    vec3 energy = ecol * vein * inten;
    energy += vec3(0.72, 0.62, 1.0) * u_crackle * 0.10 * (0.6 + 0.4 * noise(uv * 3.0 + u_time * 0.7));
    float a = clamp(max(energy.r, max(energy.g, energy.b)), 0.0, 1.0);
    fragColor = vec4(energy, a * 0.92) * qt_Opacity;
}
