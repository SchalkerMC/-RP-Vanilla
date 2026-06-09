#version 150

#moj_import <minecraft:globals.glsl>

uniform sampler2D InSampler;     // minecraft:main
uniform sampler2D DetectSampler; // 1x1 yellow detection result (R = 1.0 if yellow present)

in vec2 texCoord;

out vec4 fragColor;

#define SHAKE_STRENGTH 0.08

// 15 секунд = 12.5 в единицах (GameTime * 1000)
// Используем очень длинный период (1000.0 = весь игровой день ~20 мин),
// чтобы цикл почти никогда не сбрасывался во время игры.
// Экспоненциальное затухание делает амплитуду ~0 уже через 15 секунд.
void main() {
    vec2  detect      = texture(DetectSampler, vec2(0.5)).rg;
    float yellowSignal = detect.r * (1.0 - detect.g); // red disables shake

    float t = GameTime * 1000.0;

    // 15 секунд = 12.5 в t-единицах
    float cycleT  = clamp(mod(t, 1000.0) / 12.5, 0.0, 1.0);
    // smoothstep: плавный старт и плавное угасание до нуля
    float fadeOut = 1.0 - smoothstep(0.0, 1.0, cycleT);

    float amp = yellowSignal * SHAKE_STRENGTH * fadeOut;
    float shakeX = sin(t * 8.0) * amp;
    float shakeY = cos(t * 6.5) * amp * 0.6;

    vec2 uv = clamp(texCoord + vec2(shakeX, shakeY), 0.0, 1.0);
    fragColor = texture(InSampler, uv);
}
