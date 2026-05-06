#version 150

uniform sampler2D InSampler;

in vec2 texCoord;

out vec4 fragColor;

void main() {
    vec4 c = texture(InSampler, texCoord);
    // Yellow team (#FFFF55): R>0.5, G>0.5, B<0.4 — hide it
    if (c.a > 0.05 && c.r > 0.5 && c.g > 0.5 && c.b < 0.4) {
        fragColor = vec4(0.0);
    } else {
        fragColor = c;
    }
}
