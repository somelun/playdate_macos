#include <metal_stdlib>
using namespace metal;

struct VSIn {
    float2 position [[attribute(0)]];
    float2 uv       [[attribute(1)]];
};

struct VSOut {
    float4 position [[position]];
    float2 uv;
};

vertex VSOut vert_main(uint vid [[vertex_id]],
                       const device VSIn *verts [[buffer(0)]]) {
    VSOut o;
    o.position = float4(verts[vid].position, 0.0, 1.0);
    o.uv = verts[vid].uv;
    return o;
}

fragment float4 frag_main(VSOut in [[stage_in]],
                          texture2d<float> tex [[texture(0)]],
                          sampler s [[sampler(0)]]) {
    float g = tex.sample(s, in.uv).r;               // 0..1

    // Map white (1.0) to grey (0.5), keep black (0.0) as black
    float grey_value = g * 0.5;

    return float4(float3(grey_value, grey_value, grey_value), 1.0);
}
