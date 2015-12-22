//
//  Shaders.metal
//  MetalByExample
//
//  Created by Jared Jones on 12/19/15.
//  Copyright © 2015 Jared Jones. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct Vertex {
    float4 position [[position]];
    float4 color;
};

struct Uniforms {
    float4x4 MVP;
};

vertex Vertex vertex_main(device Vertex *verticies [[buffer(0)]],
                          constant Uniforms *uniforms [[buffer(1)]],
                          uint vid [[vertex_id]])
{
    Vertex vertexOut;
    vertexOut.position = uniforms->MVP * verticies[vid].position;
    vertexOut.color = verticies[vid].color;
    return vertexOut;
}

fragment float4 fragment_main(Vertex inVertex[[stage_in]])
{
    return inVertex.color;
}