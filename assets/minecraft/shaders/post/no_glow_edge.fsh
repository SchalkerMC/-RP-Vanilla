#version 150

uniform sampler2D InSampler;

in vec2 texCoord;

out vec4 fragColor;

void main() {
    vec4 center = texture(InSampler, texCoord);

    // Not inside the outline silhouette — transparent
    if (center.a < 0.1) {
        fragColor = vec4(0.0);
        return;
    }

    // Edge: pixel is inside silhouette but a neighbor (at 2px) is outside
    // This produces a ~2px wide ring at the outer boundary of the silhouette
    vec2 d = 2.0 / vec2(textureSize(InSampler, 0));

    bool isEdge =
        texture(InSampler, texCoord + vec2( d.x,  0.0)).a < 0.1 ||
        texture(InSampler, texCoord + vec2(-d.x,  0.0)).a < 0.1 ||
        texture(InSampler, texCoord + vec2( 0.0,  d.y)).a < 0.1 ||
        texture(InSampler, texCoord + vec2( 0.0, -d.y)).a < 0.1;

    fragColor = isEdge ? center : vec4(0.0);
}
