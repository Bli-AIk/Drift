#version 330 core
in vec2 v_texCoord;
out vec4 fragColor;

uniform sampler2D u_currentTexture;
uniform vec2 u_resolution;
uniform float strength;
uniform float angle;

void main() {
    vec4 original = texture(u_currentTexture, v_texCoord);
    if (strength < 0.01) {
        fragColor = original;
        return;
    }

    float radiansAngle = radians(angle);
    vec2 axis = vec2(cos(radiansAngle), sin(radiansAngle));
    vec2 offset = axis * clamp(strength, 0.0, 80.0) / max(u_resolution, vec2(1.0));
    vec3 total = vec3(0.0);
    float weightSum = 0.0;
    for (int i = -8; i <= 8; ++i) {
        float position = float(i) / 8.0;
        float weight = exp(-2.0 * position * position);
        vec2 uv = clamp(v_texCoord + offset * position, 0.0, 1.0);
        total += texture(u_currentTexture, uv).rgb * weight;
        weightSum += weight;
    }
    fragColor = vec4(total / max(weightSum, 0.001), original.a);
}
