//
//  Transforms.swift
//  MetalByExample
//
//  Created by Jared Jones on 12/21/15.
//  Copyright © 2015 Jared Jones. All rights reserved.
//

import Foundation
import MetalKit

func Identity() -> matrix_float4x4 {
    let X: float4 = [1,0,0,0]
    let Y: float4 = [0,1,0,0]
    let Z: float4 = [0,0,1,0]
    let W: float4 = [0,0,0,1]
    let mat: matrix_float4x4 = matrix_float4x4(columns: (X,Y,Z,W))
    return mat
}

func Translation(t:float3) -> matrix_float4x4
{
    let X: float4 = [1,0,0,0]
    let Y: float4 = [0,1,0,0]
    let Z: float4 = [0,0,1,0]
    let W: float4 = [t.x,t.y,t.z,1]
    let mat: matrix_float4x4 = matrix_float4x4(columns: (X,Y,Z,W))
    return mat
}
func PerspectiveProjection(aspect:Float, fovy:Float, near:Float, far:Float) -> matrix_float4x4 {
    let yScale:Float = 1 / tan(fovy * 0.5)
    let xScale:Float = yScale / aspect
    let zRange:Float = far - near
    let zScale:Float = -(far + near) / zRange
    let wzScale:Float = -2 * far * near / zRange
    
    let P: float4 = [xScale,0,0,0]
    let Q: float4 = [0,yScale,0,0]
    let R: float4 = [0,0,zScale, -1]
    let S: float4 = [0,0,wzScale,0]
    let mat: matrix_float4x4 = matrix_float4x4(columns: (P,Q,R,S))
    return mat
}