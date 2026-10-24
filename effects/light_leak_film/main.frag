#version 330 core
in vec2 v_texCoord;
out vec4 fragColor;
uniform sampler2D u_currentTexture;
uniform float u_time;
uniform float intensity;
uniform float warmth;
uniform float spread;
uniform float speed;

void main() {
    vec4 original = texture(u_currentTexture, v_texCoord);
    vec2 uv = v_texCoord;
    float phase = u_time * speed;
    float centerX = -0.10 + 0.23 * sin(phase * 0.46 + 0.4);
    float centerY = 0.35 + 0.30 * sin(phase * 0.32 + 1.3);
    vec2 d = (uv - vec2(centerX, centerY)) / vec2(max(spread, 0.2) * 0.67, 0.92);
    float mainLeak = exp(-dot(d, d) * 2.7);
    float rim = exp(-pow((uv.x - 1.13 - 0.09 * sin(phase * 0.65)) / (0.30 * spread), 2.0) * 1.6);
    float stripe = exp(-pow((uv.x - 0.14 - 0.03 * sin(phase)) / (0.13 * spread), 2.0)) * 0.22;
    vec3 warm = mix(vec3(0.92, 0.26, 0.62), vec3(1.0, 0.52, 0.10), warmth);
    vec3 leak = warm * mainLeak + vec3(1.0, 0.22, 0.36) * rim + vec3(1.0, 0.70, 0.25) * stripe;
    float amount = clamp(intensity, 0.0, 1.0);
    vec3 color = 1.0 - (1.0 - original.rgb) * exp(-leak * (1.8 * amount));
    fragColor = vec4(clamp(color, 0.0, 1.0), original.a);
}
