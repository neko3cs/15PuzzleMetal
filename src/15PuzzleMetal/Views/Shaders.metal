//
//  Shaders.metal
//  15PuzzleMetal
//

#include <metal_stdlib>
#include <simd/simd.h>
#import "ShaderTypes.h"

using namespace metal;

typedef struct
{
    float3 position [[attribute(VertexAttributePosition)]];
    float2 texCoord [[attribute(VertexAttributeTexcoord)]];
} Vertex;

typedef struct
{
    float4 position [[position]];
    float2 texCoord;
} ColorInOut;

vertex ColorInOut vertexShader(Vertex in [[stage_in]],
                               constant GlobalUniforms & globalUniforms [[ buffer(2) ]],
                               constant TileUniforms   & tileUniforms   [[ buffer(3) ]])
{
    ColorInOut out;
    float4 position = float4(in.position, 1.0);
    out.position = globalUniforms.projectionMatrix * tileUniforms.modelMatrix * position;
    
    // Scale and offset UV coordinates to pick the right number from the atlas
    out.texCoord = in.texCoord * tileUniforms.uvScale + tileUniforms.uvOffset;
    
    return out;
}

fragment float4 fragmentShader(ColorInOut in [[stage_in]],
                               texture2d<half> colorMap [[ texture(TextureIndexColor) ]])
{
    constexpr sampler colorSampler(mip_filter::linear,
                                   mag_filter::linear,
                                   min_filter::linear);

    half4 colorSample = colorMap.sample(colorSampler, in.texCoord.xy);

    return float4(colorSample);
}
