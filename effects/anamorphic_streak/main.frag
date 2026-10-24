#version 330 core
in vec2 v_texCoord;
out vec4 fragColor;
uniform sampler2D u_currentTexture;
uniform float intensity;
uniform float streakLength;
uniform float threshold;
uniform float cool;

void main() {
    vec4 original = texture(u_currentTexture, v_texCoord);
    vec3 streak = vec3(0.0);
    float weights = 0.0;
    for (int i = -8; i <= 8; ++i) {
        float offset = float(i) / 8.0;
        vec2 uv = vec2(clamp(v_texCoord.x + offset * streakLength, 0.0, 1.0), v_texCoord.y);
        vec3 sampleColor = texture(u_currentTexture, uv).rgb;
        float luminance = dot(sampleColor, vec3(0.2126, 0.7152, 0.0722));
        float bright = max(0.0, luminance - threshold);
        float weight = exp(-abs(offset) * 2.5);
        streak += sampleColor * bright * weight;
        weights += weight;
    }
    vec3 tint = mix(vec3(1.0, 0.65, 0.38), vec3(0.42, 0.66, 1.0), cool);
    vec3 color = clamp(original.rgb + (streak / max(weights, 0.001)) * tint * intensity * 5.0,
                       0.0, 1.0);
    fragColor = vec4(color, original.a);
}
