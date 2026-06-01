#version 330

uniform sampler2D OutlineSampler;
uniform sampler2D RawOutlineSampler;
uniform sampler2D MainSampler;

in vec2 texCoord;
in vec2 oneTexel;

out vec4 fragColor;

void main() {
    vec4 rawoutline = texture(RawOutlineSampler, texCoord);
    vec4 outline = texture(OutlineSampler, texCoord);
    vec4 main = texture(MainSampler, texCoord);
    fragColor = main;

    float rad = 1.0;
    for (float x = -rad; x <= rad; x++) {
        for (float z = -rad; z <= rad; z++) {
            vec2 pos = texCoord + oneTexel * vec2(x, z);
            float r = round(texture(RawOutlineSampler, pos).r * 255.0);
            if (r == 254.0 || r == 253.0 || r == 252.0) {
                return;
            }
        }
    }

    if (rawoutline.rgb != outline.rgb) {
        float r = round(rawoutline.r * 255.0);
        if (r != 252.0 && r != 253.0 && r != 254.0) {
            fragColor = outline;
        }
    }
}
