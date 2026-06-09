#version 150

out vec2 texCoord;
out vec2 oneTexel;

in vec4 Position;

layout(std140) uniform SamplerInfo {
    vec2 OutSize;
    vec2 InSize;
};

#moj_import <minecraft:projection.glsl>
#moj_import <minecraft:dynamictransforms.glsl>

void main() {
    vec4 outPos = ProjMat * vec4(Position.xy * OutSize, 0.0, 1.0);
    gl_Position = vec4(outPos.xy, 0.2, 1.0);
    oneTexel = 1.0 / InSize;
    texCoord = Position.xy;
}
