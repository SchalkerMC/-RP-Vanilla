#version 150

uniform sampler2D InSampler; // entity_outline (original)

in vec2 texCoord;

out vec4 fragColor;

bool isYellow(vec4 c) {
    return c.a > 0.05 && c.r > 0.5 && c.g > 0.5 && c.b < 0.4;
}

bool isRed(vec4 c) {
    return c.a > 0.05 && c.r > 0.5 && c.g < 0.4 && c.b < 0.4;
}

void main() {
    // This pass outputs to a 1x1 target, so it runs exactly once.
    // Sample entity_outline on a dense 32x32 grid covering the full screen.
    float yellow = 0.0;
    float red    = 0.0;
    for (int x = 0; x < 32; x++) {
        for (int y = 0; y < 32; y++) {
            vec2 p = vec2(float(x) / 31.0, float(y) / 31.0);
            vec4 c = texture(InSampler, p);
            if (isYellow(c)) yellow = 1.0;
            if (isRed(c))    red    = 1.0;
        }
    }
    // R = yellow present, G = red present
    fragColor = vec4(yellow, red, 0.0, 1.0);
}
