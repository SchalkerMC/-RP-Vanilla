#version 150

#moj_import <minecraft:globals.glsl>

uniform sampler2D InSampler;     // swap_edge (edge outline)
uniform sampler2D DetectSampler; // 1x1 yellow detection

in vec2 texCoord;

out vec4 fragColor;

void main() {
    float yellowSignal = texture(DetectSampler, vec2(0.5)).r;

    float t = GameTime * 1000.0;

    float cycleT  = clamp(mod(t, 1000.0) / 12.5, 0.0, 1.0);
    float fadeOut = 1.0 - smoothstep(0.0, 1.0, cycleT);

    float amp = yellowSignal * 0.03 * fadeOut;
    float shakeX = sin(t * 8.0) * amp;
    float shakeY = cos(t * 6.5) * amp * 0.6;

    vec2 uv = clamp(texCoord + vec2(shakeX, shakeY), 0.0, 1.0);
    fragColor = texture(InSampler, uv);
}
