#version 330 core
in vec2 v_texCoord;
out vec4 fragColor;

uniform sampler2D u_currentTexture;
uniform float exposure;
uniform float contrast;
uniform float highlights;
uniform float shadows;
uniform float vibrance;
uniform float temperature;
uniform float tint;
uniform float fade;

float luma(vec3 c) {
    return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

void main() {
    vec4 original = texture(u_currentTexture, v_texCoord);
    vec3 c = max(original.rgb, vec3(0.0));

    // A zeroed preset is an exact pass-through. Exposure is measured in stops.
    c *= exp2(clamp(exposure, -2.0, 2.0));
    c = (c - 0.5) * (1.0 + contrast * 0.8) + 0.5;

    float y = clamp(luma(c), 0.0, 1.0);
    float shadowMask = 1.0 - smoothstep(0.05, 0.58, y);
    float highlightMask = smoothstep(0.42, 0.98, y);
    c += 0.45 * shadows * shadowMask * (shadows >= 0.0 ? (1.0 - c) : c);
    c += 0.45 * highlights * highlightMask * (highlights >= 0.0 ? (1.0 - c) : c);

    // Target less saturated colors first, retaining richly colored subjects.
    float sat = max(max(c.r, c.g), c.b) - min(min(c.r, c.g), c.b);
    float vib = 1.0 + vibrance * (1.0 - clamp(sat, 0.0, 1.0));
    c = mix(vec3(luma(c)), c, max(0.0, vib));

    c *= vec3(1.0 + temperature * 0.14,
              1.0 - abs(temperature) * 0.035,
              1.0 - temperature * 0.14);
    c *= vec3(1.0 + tint * 0.07, 1.0 - tint * 0.10, 1.0 + tint * 0.07);
    c = mix(c, c * 0.85 + vec3(0.09), clamp(fade, 0.0, 1.0));
    fragColor = vec4(clamp(c, 0.0, 1.0), original.a);
}
