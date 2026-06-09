#version 330

#moj_import <minecraft:globals.glsl>

uniform sampler2D InSampler;
uniform sampler2D RawScreenSampler;
uniform sampler2D MemeImageSampler;

in vec2 texCoord;

out vec4 fragColor;

const float PI = 3.14159265;

// --- Простой value-noise + fbm для «вен» ---
float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 345.45));
    p += dot(p, p + 34.345);
    return fract(p.x * p.y);
}

float valueNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash21(i);
    float b = hash21(i + vec2(1.0, 0.0));
    float c = hash21(i + vec2(0.0, 1.0));
    float d = hash21(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 4; i++) {
        v += a * valueNoise(p);
        p *= 2.0;
        a *= 0.5;
    }
    return v;
}

// Вены: «хребтовый» шум с доменным искажением, заточенный в тонкие линии.
float veinMask(vec2 uv, float t) {
    vec2 q = uv * 5.0;
    q += 0.6 * vec2(fbm(q + vec2(0.0, t * 0.15)), fbm(q + vec2(7.3, t * 0.15)));
    float n = fbm(q);
    float ridge = 1.0 - abs(2.0 * n - 1.0); // линии вдоль гребней шума
    ridge = pow(clamp(ridge, 0.0, 1.0), 6.0); // утончаем
    return ridge;
}

void main() {
    vec4 inTexel = texture(InSampler, texCoord);
    vec4 controlTexel = texture(RawScreenSampler, vec2(0.5, 0.5));

    fragColor = inTexel;

    int marker = int(round(controlTexel.r * 255.0));

    // --- Эффект крена камеры (как было) ---
    if (marker == 253) {
        int contrCutsceneId = int(int(round(controlTexel.g * 255.0 * 256.0 + controlTexel.b * 255.0)) / 4.0) * 4;
        int effectsCount = 4;
        float effectId = contrCutsceneId / effectsCount - 1000.0;

        float angle = effectId * 0.1 / 180.0 * 3.1415;
        vec2 coord = texCoord - 0.5;
        coord.x *= ScreenSize.x / ScreenSize.y;
        float cosA = cos(angle);
        float sinA = sin(angle);
        vec2 rotated = vec2(cosA * coord.x + sinA * coord.y, -sinA * coord.x + cosA * coord.y);
        rotated.x /= ScreenSize.x / ScreenSize.y;
        rotated *= 1.0 - abs(sinA) * 0.5;
        rotated += 0.5;

        vec2 outside = max(vec2(0.0), max(-rotated, rotated - 1.0));
        if (outside.x > 0.0 || outside.y > 0.0) {
            fragColor = vec4(0.0, 0.0, 0.0, 1.0);
        } else {
            float vigWidth = abs(sinA) * 0.18;
            vec2 edgeDist = min(rotated, 1.0 - rotated);
            float nearestEdge = min(edgeDist.x, edgeDist.y);
            float vignette = smoothstep(0.0, max(vigWidth, 0.0001), nearestEdge);
            fragColor = vec4(texture(InSampler, rotated).rgb * vignette, 1.0);
        }
        return;
    }

    // --- Виньетка глубины: 3 стадии (R=252, стадия в G) ---
    if (marker == 252) {
        int stage = int(round(controlTexel.g * 255.0));

        float aspect = ScreenSize.x / ScreenSize.y;
        vec2 uv = texCoord - 0.5;
        uv.x *= aspect;
        float dist = length(uv);

        // Базовая маска виньетки: 0 в центре, 1 у краёв.
        float edge = smoothstep(0.30, 0.95, dist);

        float t = GameTime * 1000.0;
        vec3 col = inTexel.rgb;

        if (stage <= 1) {
            // Стадия 1: спокойная тёмная виньетка, ~25%.
            float v = 0.25 * edge;
            col = inTexel.rgb * (1.0 - v);
        } else if (stage == 2) {
            // Стадия 2: ~30%, пульсирует красным.
            float pulse = 0.6 + 0.4 * sin(t * 5.0);
            float v = 0.30 * edge * pulse;
            col = mix(inTexel.rgb, vec3(0.35, 0.0, 0.0), v);
        } else {
            // Стадия 3: ~50%, пульсирует и обрастает «венами».
            float pulse = 0.55 + 0.45 * sin(t * 6.5);
            float v = 0.50 * edge * pulse;
            col = mix(inTexel.rgb, vec3(0.40, 0.0, 0.0), v);

            float veins = veinMask(uv * 1.6, t);
            veins *= smoothstep(0.20, 0.95, dist);   // только ближе к краям
            veins *= 0.55 + 0.45 * pulse;            // пульсация вен
            col = mix(col, vec3(0.55, 0.0, 0.02), clamp(veins, 0.0, 1.0) * 0.85);
        }

        fragColor = vec4(col, 1.0);
        return;
    }

    // --- Мем-оверлей (R=251), доля непрозрачности в G (0..1) ---
    if (marker == 251) {
        float opacity = clamp(controlTexel.g, 0.0, 1.0);
        float aspect = ScreenSize.x / ScreenSize.y;
        // Доля высоты экрана, которую занимает КВАДРАТНАЯ картинка (меньше → «дальше»).
        const float MEME_SCALE = 0.8;
        // Центрируем по обеим осям и масштабируем, сохраняя пропорции 1:1.
        vec2 uv;
        uv.x = (texCoord.x - 0.5) * aspect / MEME_SCALE + 0.5;
        uv.y = (texCoord.y - 0.5) / MEME_SCALE + 0.5;
        if (uv.x >= 0.0 && uv.x <= 1.0 && uv.y >= 0.0 && uv.y <= 1.0) {
            // Если картинка окажется перевёрнутой — заменить (1.0 - uv.y) на uv.y.
            vec4 meme = texture(MemeImageSampler, vec2(uv.x, 1.0 - uv.y));
            fragColor = vec4(mix(inTexel.rgb, meme.rgb, opacity * meme.a), 1.0);
        } else {
            fragColor = inTexel;
        }
        return;
    }
}
