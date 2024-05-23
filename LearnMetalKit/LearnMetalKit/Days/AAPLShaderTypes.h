//
//  AAPLShaderTypes.h
//  LearnMetalKit
//  Created by JoyTim on 2024/5/22
//  Copyright © 2024 ___ORGANIZATIONNAME___. All rights reserved.
//
    

#ifndef AAPLShaderTypes_h
#define AAPLShaderTypes_h
#include <simd/simd.h>

typedef enum AAPLVertexInputIndex
{
    AAPLVertexInputIndexVertices     = 0,
    AAPLVertexInputIndexViewportSize = 1,
} AAPLVertexInputIndex;

//  This structure defines the layout of vertices sent to the vertex
//  shader. This header is shared between the .metal shader and C code, to guarantee that
//  the layout of the vertex array in the C code matches the layout that the .metal
//  vertex shader expects.
typedef struct
{
    vector_float2 position;
    vector_float4 color;
} AAPLVertex;

#endif /* AAPLShaderTypes_h */
