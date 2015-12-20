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

vertex Vertex vertex_main(device Vertex *verticies [[buffer(0)]],
                          uint vid [[vertex_id]])
{
    return verticies[vid];
}

fragment float4 fragment_main(Vertex inVertex[[stage_in]])
{
    return inVertex.color;
}