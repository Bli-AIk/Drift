#version 330 core
in vec2 v_texCoord; out vec4 fragColor;
uniform sampler2D u_currentTexture;
uniform float exposure; uniform float contrast; uniform float highlights; uniform float shadows;
uniform float whites; uniform float blacks;
uniform float temperature; uniform float tint; uniform float saturation; uniform float vibrance;
uniform vec2 lift; uniform float liftLuma; uniform vec2 gamma; uniform float gammaLuma;
uniform vec2 gain; uniform float gainLuma;
uniform sampler2D curveMaster; uniform sampler2D curveR; uniform sampler2D curveG; uniform sampler2D curveB;
uniform sampler2D look; uniform float lookAmount;

float Y(vec3 c) { return dot(c, vec3(0.2126, 0.7152, 0.0722)); }

vec3 srgbToLinear(vec3 c) {
    return mix(pow(max((c + 0.055) / 1.055, 0.0), vec3(2.4)), c / 12.92, lessThanEqual(c, vec3(0.04045)));
}

vec3 linearToSrgb(vec3 c) {
    return mix(1.055 * pow(max(c, 0.0), vec3(1.0 / 2.4)) - 0.055, c * 12.92, lessThanEqual(c, vec3(0.0031308)));
}

vec3 kelvinRGB(float K) {
    float t = K / 100.0;
    float r, g, b;
    if (t <= 66.0) {
        r = 1.0;
        g = clamp((99.4708025861 * log(t) - 161.1195681661) / 255.0, 0.0, 1.0);
        b = t <= 19.0 ? 0.0 : clamp((138.5177312231 * log(t - 10.0) - 305.0447927307) / 255.0, 0.0, 1.0);
    } else {
        r = clamp(329.698727446 / 255.0 * pow(t - 60.0, -0.1332047592), 0.0, 1.0);
        g = clamp(288.1221695283 / 255.0 * pow(t - 60.0, -0.0755148492), 0.0, 1.0);
        b = 1.0;
    }
    return max(vec3(r, g, b), 1e-4);
}

vec3 off(vec2 v) {
    vec3 yiq = vec3(0.0, 0.5957 * v.x, 0.5226 * v.y);
    return vec3(yiq.x + 0.956 * yiq.y + 0.619 * yiq.z,
                yiq.x - 0.272 * yiq.y - 0.647 * yiq.z,
                yiq.x - 1.106 * yiq.y + 1.703 * yiq.z);
}

float cv(sampler2D s, float x) {
    return texture(s, vec2((clamp(x, 0.0, 1.0) * 255.0 + 0.5) / 256.0, 0.5)).r;
}

vec3 lutSample(sampler2D t, vec3 c) {
    float bz = c.b * 32.0;
    float b0 = floor(bz);
    float b1 = min(b0 + 1.0, 32.0);
    float f = bz - b0;
    float v = (c.g * 32.0 + 0.5) / 33.0;
    float u0 = (b0 * 33.0 + c.r * 32.0 + 0.5) / 1089.0;
    float u1 = (b1 * 33.0 + c.r * 32.0 + 0.5) / 1089.0;
    return mix(texture(t, vec2(u0, v)).rgb, texture(t, vec2(u1, v)).rgb, f);
}

void main() {
    vec4 src = texture(u_currentTexture, v_texCoord);
    float a = max(src.a, 1e-5);
    vec3 c = src.rgb / a;

    vec3 lin = srgbToLinear(c);
    lin *= exp2(exposure);

    float K = 6500.0 * exp2(-temperature * 1.1);
    vec3 wb = kelvinRGB(K) / kelvinRGB(6500.0);
    wb /= Y(wb);
    vec3 tintV = vec3(1.0, 1.0 - 0.3 * tint, 1.0);
    tintV /= Y(tintV);
    lin *= wb * tintV;
    c = linearToSrgb(max(lin, 0.0));

    float p = 0.435;
    float k = clamp(exp(contrast * 1.2), 0.3, 3.3);
    vec3 x = clamp(c, 0.0, 1.0);
    vec3 lo = p * pow(max(x / p, 0.0), vec3(k));
    vec3 hi = 1.0 - (1.0 - p) * pow(max((1.0 - x) / (1.0 - p), 0.0), vec3(k));
    c = mix(lo, hi, step(p, x));

    float tlo = 0.15 * blacks;
    float thi = 1.0 + 0.15 * whites;
    c = tlo + c * (thi - tlo);
    float y0 = Y(c);
    float sW = 1.0 - smoothstep(0.0, 0.6, y0);
    float hW = smoothstep(0.4, 1.0, y0);
    float dy = 0.3 * shadows * sW * sW + 0.3 * highlights * hW * hW;
    vec3 cScaled = c * (y0 + dy) / max(y0, 1e-4);
    vec3 cAdd = c + dy;
    c = mix(cAdd, cScaled, smoothstep(0.03, 0.08, y0));

    vec3 L = 0.25 * (off(lift) + vec3(liftLuma));
    vec3 Gm = 0.5 * (off(gain) + vec3(gainLuma));
    vec3 G = 0.5 * (off(gamma) + vec3(gammaLuma));
    c = pow(max(c * (1.0 + Gm - L) + L, 1e-6), exp2(-G));

    c.r = cv(curveR, cv(curveMaster, c.r));
    c.g = cv(curveG, cv(curveMaster, c.g));
    c.b = cv(curveB, cv(curveMaster, c.b));

    float yy = Y(c);
    float s = max(c.r, max(c.g, c.b)) - min(c.r, min(c.g, c.b));
    c = yy + (c - yy) * saturation * (1.0 + vibrance * (1.0 - s));
    c = clamp(c, 0.0, 1.0);

    c = mix(c, lutSample(look, c), lookAmount);

    fragColor = vec4(clamp(c, 0.0, 1.0) * src.a, src.a);
}
