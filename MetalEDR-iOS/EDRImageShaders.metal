/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Metal shaders used for this sample
*/

#include <metal_stdlib>

using namespace metal;

#include "EDRImageShaderTypes.h"

struct RasterizerData
{
    float4 position [[position]];
    float2 textureCoord;
};

vertex RasterizerData
vertexShader(uint vertexID [[vertex_id]],
             constant EDRImageVertex *vertices [[buffer(0)]])
{
    RasterizerData out;

    out.position = float4(vertices[vertexID].position, 0, 1);
    out.textureCoord = vertices[vertexID].textureCoord;
    
    return out;
}

fragment float4 fragmentShader(RasterizerData in [[stage_in]],
                               sampler sampler2d,
                               texture2d<float, access::sample> texture [[texture(0)]])
{
    float4 result = texture.sample(sampler2d, in.textureCoord);
    
    // pixels over 1.0 will display brighter than "SDR white"
    // you can mock here, like:
    // result = result * 5;
    
    return result;
}

