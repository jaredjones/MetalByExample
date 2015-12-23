//
//  Transforms.swift
//  MetalByExample
//
//  Created by Jared Jones on 12/21/15.
//  Copyright © 2015 Jared Jones. All rights reserved.
//

import Foundation
import MetalKit

func matrix_float4x4_identity() -> matrix_float4x4 {
    let X: float4 = [1,0,0,0]
    let Y: float4 = [0,1,0,0]
    let Z: float4 = [0,0,1,0]
    let W: float4 = [0,0,0,1]
    let mat: matrix_float4x4 = matrix_float4x4(columns: (X,Y,Z,W))
    return mat
}

func matrix_float4x4_translation(t:float3) -> matrix_float4x4
{
    let X: float4 = [1,0,0,0]
    let Y: float4 = [0,1,0,0]
    let Z: float4 = [0,0,1,0]
    let W: float4 = [t.x,t.y,t.z,1]
    let mat: matrix_float4x4 = matrix_float4x4(columns: (X,Y,Z,W))
    return mat
}

func matrix_float4x4_perspective(aspect:Float, fovy:Float, near:Float, far:Float) -> matrix_float4x4 {
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

func matrix_float4x4_scale(scale:Float) -> matrix_float4x4 {
    let X: float4 = [scale,0,0,0]
    let Y: float4 = [0,scale,0,0]
    let Z: float4 = [0,0,scale,0]
    let W: float4 = [0,0,0,1]
    
    let mat: matrix_float4x4 = matrix_float4x4(columns: (X,Y,Z,W))
    return mat
}

func matrix_float4x4_rotation(axis: float3, angle:Float) -> matrix_float4x4 {
    let c: Float = cos(angle)
    let s: Float = sin(angle)
    
    var X: float4 = float4()
    X.x = axis.x * axis.x + (1 - axis.x * axis.x) * c;
    X.y = axis.x * axis.y * (1 - c) - axis.z * s;
    X.z = axis.x * axis.z * (1 - c) + axis.y * s;
    X.w = 0.0;
    
    var Y: float4 = float4()
    Y.x = axis.x * axis.y * (1 - c) + axis.z * s;
    Y.y = axis.y * axis.y + (1 - axis.y * axis.y) * c;
    Y.z = axis.y * axis.z * (1 - c) - axis.x * s;
    Y.w = 0.0;
    
    var Z: float4 = float4()
    Z.x = axis.x * axis.z * (1 - c) - axis.y * s;
    Z.y = axis.y * axis.z * (1 - c) + axis.x * s;
    Z.z = axis.z * axis.z + (1 - axis.z * axis.z) * c;
    Z.w = 0.0;
    
    var W: float4 = float4()
    W.x = 0.0;
    W.y = 0.0;
    W.z = 0.0;
    W.w = 1.0;
    
    let mat: matrix_float4x4 = matrix_float4x4(columns: (X,Y,Z,W))
    return mat
}