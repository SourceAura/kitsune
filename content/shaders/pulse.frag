#version 440
// pulse.frag — energy in the glass
// Filament veins sleep in the blurred ground. A surge sends a front
// of light across them; now and then the whole field crackles. And
// the glass answers touch: a click lands as a ripple of light from
// that point. Sporadic by design — the QML side decides when; the
// shader only draws.
//
// Uniforms:
//   u_time      — continuous seconds
//   u_surge     — 0–1, surge envelope
//   u_front     — surge front position in uv.x (travels -0.35 to 1.35)
//   u_crackle   — 0–1, crackle flare envelope
//   u_calm      — baseline filament strength (a whisper)
//   u_click     — last touch point, in uv
//   u_clickAge  — seconds since that touch
//   u_aspect    — surface width / height, for round ripples

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
    vec2 u_click;
    float u_clickAge;
    float u_aspect;
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
    // the touch: water takes the point — a decelerating front, two
    // trailing crests behind it, a spectral split at each rim, and
    // the filament field wobbling the edges so they stay organic
    float ct = u_clickAge;
    if (ct >= 0.0 && ct < 3.0) {
        vec2 dp = (uv - u_click) * vec2(u_aspect, 1.0);
        float cd = length(dp);
        float wob = fbm(uv * 18.0 + u_click * 7.0) - 0.5;
        float d = cd + wob * 0.018 * smoothstep(0.0, 0.25, cd);
        float rad = 0.42 * pow(ct, 0.82);
        float env = exp(-ct * 1.25) * exp(-max(cd - rad, 0.0) * 3.0);
        vec3 prism = vec3(0.0);
        for (int k = 0; k < 3; k++) {
            float rk = rad - float(k) * 0.055;
            if (rk < 0.0) continue;
            float amp = env * (k == 0 ? 1.0 : (k == 1 ? 0.42 : 0.20));
            prism += vec3(exp(-pow((d - rk - 0.011) * 13.0, 2.0)),
                          exp(-pow((d - rk) * 13.0, 2.0)),
                          exp(-pow((d - rk + 0.011) * 13.0, 2.0))) * amp;
            prism += vec3(0.9, 0.97, 1.0) * exp(-pow((d - rk) * 24.0, 2.0)) * amp * 0.7;
        }
        float trough = -exp(-pow((d - rad - 0.035) * 11.0, 2.0)) * 0.30;
        float bloom = exp(-d * 6.0) * exp(-ct * 2.6);
        energy += prism * (0.75 + 0.5 * vein) + ecol * exp(-pow((d - rad) * 13.0, 2.0)) * env * 0.18;
        energy += vec3(trough * env);
        energy += vec3(0.85, 0.93, 1.0) * bloom * 0.16;
    }
    float a = clamp(max(energy.r, max(energy.g, energy.b)), 0.0, 1.0);
    fragColor = vec4(energy, a * 0.92) * qt_Opacity;
}
