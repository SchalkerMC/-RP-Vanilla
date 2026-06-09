#version 150

#moj_import <minecraft:globals.glsl>

uniform sampler2D InSampler;     // minecraft:main
uniform sampler2D OutlineSampler; // minecraft:entity_outline

in vec2 texCoord;

out vec4 fragColor;

bool isYellow(vec4 c) {
    // Yellow team (#FFFF55): R>0.5, G>0.5, B<0.4
    return c.a > 0.05 && c.r > 0.5 && c.g > 0.5 && c.b < 0.4;
}

void main() {
    // Sample 16 evenly-distributed points to detect if any yellow outline is on screen
    float yellowSignal = 0.0;
    for (int x = 0; x < 4; x++) {
        for (int y = 0; y < 4; y++) {
            vec2 p = vec2(float(x) / 3.0 * 0.8 + 0.1, float(y) / 3.0 * 0.8 + 0.1);
            if (isYellow(texture(OutlineSampler, p))) {
                yellowSignal = 1.0;
            }
        }
    }

    // Screen shake when yellow is present
    float t = GameTime * 1000.0;
    float amp = yellowSignal * 0.006;
    float shakeX = (sin(t * 13.7) * 0.6 + sin(t * 7.3) * 0.4) * amp;
    float shakeY = (cos(t * 11.1) * 0.6 + cos(t * 5.9) * 0.4) * amp;

    vec2 uv = clamp(texCoord + vec2(shakeX, shakeY), 0.0, 1.0);
    vec4 color = texture(InSampler, uv);

    // Composite white outline only (skip yellow)
    vec4 outline = texture(OutlineSampler, texCoord);
    if (!isYellow(outline) && outline.a > 0.05) {
        color = mix(color, outline, outline.a);
    }

    fragColor = color;
}
