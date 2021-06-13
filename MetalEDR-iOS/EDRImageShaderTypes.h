/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Header containing types and enum constants shared between Metal shaders and C/ObjC source
*/

#ifndef EDRImageShaderTypes_h
#define EDRImageShaderTypes_h

#include <simd/simd.h>

// Buffer index values shared between shader and C code to ensure Metal shader buffer inputs
// match Metal API buffer set calls.
typedef enum EDRImageVertexInputIndex
{
    EDRImageVertexInputIndexVertices     = 0,
    EDRImageVertexInputIndexViewportSize = 1,
} EDRImageVertexInputIndex;

//  This structure defines the layout of vertices sent to the vertex
//  shader. This header is shared between the .metal shader and C code, to guarantee that
//  the layout of the vertex array in the C code matches the layout that the .metal
//  vertex shader expects.
typedef struct
{
    vector_float2 position;
    vector_float2 textureCoord;
} EDRImageVertex;

#endif /* EDRImageShaderTypes_h */
